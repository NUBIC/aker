require File.expand_path('../../spec_helper', __FILE__)

require 'bcsec/central_parameters'

module Bcsec
  describe CentralParameters do
    describe "default set" do
      before do
        @defaults = CentralParameters.new
      end

      describe "for cc_pers" do
        it "includes the username" do
          @defaults[:cc_pers][:user].should == "cc_pers"
        end

        it "includes the jdbc driver" do
          @defaults[:cc_pers][:jdbc][:driver].should == "oracle.jdbc.OracleDriver"
        end

        it "includes the activerecord adapter" do
          @defaults[:cc_pers][:activerecord][:adapter].should == "oracle_enhanced"
        end
      end

      describe "for netid" do
        it "includes the ldap server" do
          @defaults[:netid][:'ldap-servers'].should == ["registry.northwestern.edu"]
        end
      end

      describe "for policy" do
        it "includes the lockout duration" do
          @defaults[:policy][:'lockout-duration-seconds'].should == 600
        end

        it "includes the lockout attempt count" do
          @defaults[:policy][:'lockout-attempts'].should == 5
        end

        it "includes the session timeout" do
          @defaults[:policy][:'session-timeout'].should == 30.minutes
        end
      end
    end

    describe "creating from a YAML file" do
      before do
        @actual = CentralParameters.new(File.expand_path("../bcsec-sample.yml", __FILE__))
      end

      it "loads new keys" do
        @actual[:netid][:user].should == "cn=foo"
      end

      it "loads top-level keys that aren't in the default set" do
        @actual[:foo][:bar].should == 'baz'
      end

      it "overrides default keys" do
        @actual[:cc_pers][:user].should == "cc_pers_foo"
      end

      it "includes default keys which aren't overridden" do
        @actual[:cc_pers][:activerecord][:adapter].should == "oracle_enhanced"
      end
    end

    describe "creating from a hash" do
      before do
        @source = {
          :cc_pers => { :user => 'cc_pers_bar', :password => 'secret' },
          :foo => { :bar => 'baz' }
        }
        @actual = CentralParameters.new(@source)
      end

      it "loads new keys" do
        @actual[:cc_pers][:password].should == 'secret'
      end

      it "loads top-level keys that aren't in the default set" do
        @actual[:foo][:bar].should == 'baz'
      end

      it "overrides default keys" do
        @actual[:cc_pers][:user].should == 'cc_pers_bar'
      end

      it "includes default keys which aren't overridden" do
        @actual[:cc_pers][:activerecord][:adapter].should == 'oracle_enhanced'
      end

      it "does not reflect changes to the source hash" do
        @source[:cc_pers][:user] = 'cc_pers_etc'
        @actual[:cc_pers][:user].should == 'cc_pers_bar'
      end
    end
  end
end
