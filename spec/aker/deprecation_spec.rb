require File.expand_path("../../spec_helper", __FILE__)

require 'rational'

module Aker
  describe Deprecation do
    # adds a level of indirection so that we can test that
    # notifications are reported on the caller of the method
    # that calls notify.
    def indirect_notify(*args)
      Deprecation.notify(*args)
    end

    describe "for a future version" do
      before do
        indirect_notify("app_name is deprecated.", "7.8")
      end

      it "reports a deprecation warning" do
        Deprecation.mode.messages.first[:message].should ==
          "DEPRECATION WARNING: app_name is deprecated.  " <<
          "It will be removed from aker in version 7.8 or later.  " <<
          "(Called from deprecation_spec.rb:#{__LINE__ - 7}.)"
      end

      it "reports it as deprecated" do
        Deprecation.mode.messages.first[:level].should == :deprecated
      end
    end

    describe "for a past version" do
      after do
        Deprecation.mode.reset # prevent the very-obsolete spec failure
      end

      before do
        indirect_notify("use_cas is deprecated.  Please replace it with frob.", "1.7")
      end

      it "builds a useful message from the parameters" do
        Deprecation.mode.messages.first[:message].should ==
          "OBSOLETE API USED: use_cas is deprecated.  Please replace it with frob.  " <<
          "It is no longer functional as of aker 1.7 " <<
          "and could be removed in any future version.  " <<
          "(Called from deprecation_spec.rb:#{__LINE__ - 8}.)"
      end

      it "reports it as obsolete" do
        Deprecation.mode.messages.first[:level].should == :obsolete
      end
    end

    describe "for the current version" do
      before do
        indirect_notify("something is deprecated right now", Aker::VERSION)
      end

      it "reports it as obsolete" do
        Deprecation.mode.messages.first[:level].should == :obsolete
      end
    end

    describe "in test mode" do
      # ... which is installed in spec_helper

      after do
        Deprecation.mode.reset # prevent the very-obsolete spec failure
      end

      it "does not raise an error for a slightly obsolete version" do
        one_minor_back = Aker::VERSION.split('.').collect(&:to_i).tap { |v|
          v[0,2] = ("%.1f" % (Rational(v[0] * 10 + v[1], 10) - Rational(1, 10))).split('.')
        }.join(".")
        indirect_notify("not too old", one_minor_back)
        lambda { Deprecation.mode.fail_if_any_very_obsolete }.should_not raise_error
      end

      it "registers a spec failure for a very obsolete version" do
        indirect_notify("particularly old", "1.0")
        lambda { Deprecation.mode.fail_if_any_very_obsolete }.
          should raise_error(RuntimeError, /OBSOLETE.*particularly old/)
      end
    end

    describe "default mode" do
      before do
        @test_mode, Deprecation.mode = Deprecation.mode, nil
        @err = StringIO.new
        @old_err, $stderr = $stderr, @err
      end

      after do
        Deprecation.mode = @test_mode
        $stderr = @old_err
      end

      it "prints to stderr" do
        indirect_notify("ldap_server is deprecated.", "8.4")
        @err.string.should ==
          "DEPRECATION WARNING: ldap_server is deprecated.  " <<
          "It will be removed from aker in version 8.4 or later.  " +
          "(Called from deprecation_spec.rb:#{__LINE__ - 4}.)\n"
      end

      it "throws an exception for older versions" do
        lambda { indirect_notify("I'm sorry to tell you this.", "1.6") }.
          should raise_error(Aker::Deprecation::ObsoleteError, /aker 1.6/)
      end

      it "does not fail for future versions" do
        lambda { indirect_notify("bad news", "10.3.4") }.should_not raise_error
      end
    end
  end
end
