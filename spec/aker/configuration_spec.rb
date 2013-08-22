require File.expand_path('../../spec_helper', __FILE__)

describe Aker::Configuration do
  before do
    @config = blank_config
  end

  def config_from(options={}, &block)
    Aker::Configuration.new(options, &block)
  end

  def blank_config
    Aker::Configuration.new
  end

  describe "authorities" do
    it "requires at least one" do
      lambda { blank_config.authorities }.should raise_error("No authorities configured")
    end

    it "can be safely accessed if empty" do
      blank_config.authorities?.should be_false
    end
  end

  describe "portal" do
    it "must be set" do
      lambda { @config.portal }.should raise_error("No portal configured")
    end

    it "is always a symbol" do
      @config.portal = "foo"
      @config.portal.should == :foo
    end

    it "can be safely accessed if nil" do
      @config.portal?.should be_false
    end
  end

  describe "ui_mode" do
    it "defaults to :form" do
      @config.ui_mode.should == :form
    end

    it "is always a symbol" do
      @config.ui_mode = "foo"
      @config.ui_mode.should == :foo
    end
  end

  describe "api_modes" do
    it "defaults to an empty list" do
      @config.api_modes.should == []
    end

    it "is always a list of symbols" do
      @config.api_modes = %w(a b c)
      @config.api_modes.should == [:a, :b, :c]
    end

    it "rejects one nil mode" do
      @config.api_modes = nil
      @config.api_modes.should be_empty
    end

    it "removes the nil modes from a list" do
      @config.api_modes = [:a, nil, :c, nil, nil]
      @config.api_modes.should == [:a, :c]
    end
  end

  describe "#register_mode" do
    class Aker::Spec::SomeMode < Aker::Modes::Base
      def self.key
        :some
      end
    end

    let(:config) { Aker::Configuration.new(:slices => []) }

    it 'registers the mode' do
      config.register_mode Aker::Spec::SomeMode

      config.registered_modes.should == [Aker::Spec::SomeMode]
    end

    it 'rejects objects that do not have keys' do
      lambda { config.register_mode "No key here" }.
        should raise_error(/"No key here" is not usable as a Aker mode/)
    end
  end

  describe '#alias_authority' do
    let(:new_auth) { Object.new }

    it 'registers the alias' do
      @config.alias_authority :some, new_auth
      @config.authority_aliases[:some].should be new_auth
    end

    it 'registers a string alias as a symbol' do
      @config.alias_authority 'some', new_auth
      @config.authority_aliases[:some].should be new_auth
    end
  end

  describe 'global middleware installers' do
    let(:config) { Aker::Configuration.new(:slices => []) }

    describe '#register_middleware_installer' do
      [:before_authentication, :after_authentication].each do |k|
        it "accepts the #{k.inspect} key" do
          config.register_middleware_installer(k) { 'foo' }
          config.middleware_installers[k].first.call.should == 'foo'
        end
      end

      it 'rejects an unknown key' do
        lambda { config.register_middleware_installer(:in_the_middle) { 'bar' } }.
          should raise_error(/Unsupported middleware location :in_the_middle./)
      end
    end

    describe '#install_middleware' do
      let(:builder) { double(Rack::Builder) }

      before do
        config.enhance {
          before_authentication_middleware do |b|
            b.use "Before!"
          end
          after_authentication_middleware do |b|
            b.use "After!"
          end
        }
      end

      it 'installs before middleware for :before_authentication' do
        builder.should_receive(:use).once.with("Before!")
        config.install_middleware(:before_authentication, builder)
      end

      it 'installs after middleware for :after_authentication' do
        builder.should_receive(:use).once.with("After!")
        config.install_middleware(:after_authentication, builder)
      end

      it 'does nothing if there is no middleware of the specified type' do
        config.middleware_installers.clear
        builder.should_not_receive(:use)
        lambda { config.install_middleware(:before_authentication, builder) }.
          should_not raise_error
      end

      it 'fails for an unknown key' do
        lambda { config.install_middleware(:in_the_sky, builder) }.
          should raise_error(/Unsupported middleware location :in_the_sky./)
      end
    end
  end

  describe 'slices' do
    let(:a_slice) { Aker::Configuration::Slice.new { portal 'from_slice' } }

    before do
      @original_slices = Aker::Configuration.default_slices.dup
      Aker::Configuration.default_slices.clear
    end

    after do
      Aker::Configuration.default_slices.clear
      Aker::Configuration.default_slices.concat(@original_slices)
    end

    describe 'and initialization' do
      before do
        Aker::Configuration.add_default_slice a_slice
      end

      context 'without explicit slices' do
        it 'applies the default slices' do
          blank_config.portal.should == :from_slice
        end

        it 'applies any additional configuration after the default slices' do
          config_from { portal 'from_block' }.portal.should == :from_block
        end
      end

      context 'with explicit slices' do
        let(:config) do
          Aker::Configuration.new(:slices => [
              Aker::Configuration::Slice.new { ui_mode :form },
              Aker::Configuration::Slice.new { api_mode :http_basic }
            ]
          ) do
            api_mode :cas_proxy
          end
        end

        it 'applies the explicit slices' do
          config.ui_mode.should == :form
        end

        it 'does not apply the default slices' do
          config.portal?.should be_false
        end

        it 'applies any additional configuration after the explicit slices' do
          config.api_modes.should == [:cas_proxy]
        end
      end
    end

    describe '.add_default_slice' do
      it 'can add a slice from a slice instance' do
        Aker::Configuration.add_default_slice(a_slice)

        Aker::Configuration.default_slices.should == [ a_slice ]
      end

      it 'can add a slice from a block' do
        Aker::Configuration.add_default_slice {
          portal 'from_default'
        }

        Aker::Configuration.default_slices.first.should be_a Aker::Configuration::Slice
      end
    end
  end

  describe "#logger" do
    before do
      @captured_stderr = StringIO.new
      @real_stderr, $stderr = $stderr, @captured_stderr
    end

    after do
      $stderr = @real_stderr
    end

    it "defaults to something that prints to stderr" do
      @config.logger.info("Hello, world")

      @captured_stderr.string.should =~ /Hello, world/
    end

    it "can be set" do
      lambda { @config.logger = Logger.new(STDOUT) }.should_not raise_error
    end
  end

  describe "DSL" do
    describe "for basic attributes" do
      it "can set the portal" do
        config_from { portal :ENU }.portal.should == :ENU
      end

      it "can set the UI mode" do
        config_from { ui_mode :cas }.ui_mode.should == :cas
      end

      it "can set one API mode" do
        config_from { api_mode :basic }.api_modes.should == [:basic]
      end

      it "can set several API modes" do
        config_from { api_modes :basic, :api_key }.api_modes.should == [:basic, :api_key]
      end
    end

    describe "for additional authority parameters" do
      it "can set parameters for arbitrary groups" do
        config_from { foo_parameters :server => "test.local" }.
          parameters_for(:foo)[:server].should == "test.local"
      end

      it "can set (and name) one parameter at a time" do
        config_from { foo_parameter :server => "test.bar" }.
          parameters_for(:foo)[:server].should == "test.bar"
      end

      it "combines parameters from multiple calls" do
        start = config_from { netid_parameters :server => "ldap.foo.edu" }
        start.enhance { netid_parameters :username => "arb" }
        start.parameters_for(:netid)[:server].should == "ldap.foo.edu"
        start.parameters_for(:netid)[:username].should == "arb"
      end

      it 'combines arbitrarily nested hashes' do
        c = config_from { foo_parameters :bar => { :a => { :one => 1 } } }
        c.enhance { foo_parameters :bar => { :a => { :two => 2 }, :b => { :one => 4 } } }

        c.parameters_for(:foo)[:bar][:a].should == { :one => 1, :two => 2 }
        c.parameters_for(:foo)[:bar][:b].should == { :one => 4 }
      end

      it 'respects values set to nil when combining' do
        c = config_from { foo_parameters :bar => :quux }
        c.parameters_for(:foo)[:bar].should == :quux

        c.enhance { foo_parameters :bar => nil }
        c.parameters_for(:foo)[:bar].should be_nil
      end

      it 'respects values set to nil when deeply combining' do
        c = config_from { foo_parameters :bar => { :a => { :two => 2 } } }
        c.parameters_for(:foo)[:bar][:a][:two].should == 2

        c.enhance { foo_parameters :bar => { :a => { :two => nil } } }
        c.parameters_for(:foo)[:bar][:a][:two].should be_nil
      end
    end

    describe "for authorities" do
      def only_static_config(&block)
        Aker::Configuration.new(
          :slices => [Aker::Configuration::Slice.new {
            alias_authority :static, Aker::Authorities::Static
          }], &block)
      end

      it "can configure an authority from an alias symbol" do
        only_static_config { authority :static }.
          authorities.first.class.should == Aker::Authorities::Static
      end

      it "can configure an authority from an alias string" do
        only_static_config { authority "static" }.authorities.first.class.
          should == Aker::Authorities::Static
      end

      it 'can configure an authority from an alias to an alias' do
        only_static_config {
          alias_authority :moq, :static
          authority :moq
        }.authorities.first.should be_a Aker::Authorities::Static
      end

      it 'fails with a useful message with an unregistered alias' do
        lambda {
          only_static_config { authority :cas }
        }.should raise_error(/Unknown authority alias :cas./)
      end

      it "can configure an authority from a class" do
        only_static_config { authority Aker::Authorities::Static }.authorities.first.class.
          should == Aker::Authorities::Static
      end

      it "can configure an authority from an instance" do
        expected = Object.new
        only_static_config { authority expected }.authorities.first.should be expected
      end

      it "it passes the configuration to an instantiated authority" do
        actual = only_static_config { authority Struct.new(:config) }
        actual.authorities.first.config.should be actual
      end

      it "defers instantiating the authorities until the configuration is complete" do
        only_static_config {
          portal :foo

          authority Class.new {
            attr_reader :initial_portal

            def initialize(config)
              @initial_portal = config.portal
            end
          }

          portal :bar
        }.authorities.first.initial_portal.should == :bar
      end
    end

    describe "this" do
      let(:config) { config_from { foo_parameters :this => this } }

      it 'refers to the configuration being updated itself' do
        config.parameters_for(:foo)[:this].should be config
      end
    end

    describe "central parameters" do
      before do
        @actual = config_from { central File.expand_path("../aker-sample.yml", __FILE__) }
      end

      it "acquires the netid parameters" do
        @actual.parameters_for(:netid)[:user].should == "cn=foo"
      end

      it "acquires the cc_pers parameters" do
        @actual.parameters_for(:cc_pers)[:user].should == "cc_pers_foo"
      end

      it "acquires the cas parameters" do
        @actual.parameters_for(:cas)[:base_url].should == "https://cas.example.edu"
        @actual.parameters_for(:cas)[:proxy_retrieval_url].
          should == "https://cas.example.edu/retrieve_pgt"
        @actual.parameters_for(:cas)[:proxy_callback_url].
          should == "https://cas.example.edu/receive_pgt"
      end

      it "acquires all top-level parameters" do
        @actual.parameters_for(:foo)[:bar].should == "baz"
      end
    end

    describe 'middleware' do
      context 'before_authentication_middleware' do
        it 'registers under the :before_authentication key' do
          config_from { before_authentication_middleware { 'foob' } }.
            middleware_installers[:before_authentication].last.call(nil).should == 'foob'
        end
      end

      context 'after_authentication_middleware' do
        it 'registers under the :after_authentication key' do
          config_from { after_authentication_middleware { 'fooa' } }.
            middleware_installers[:after_authentication].last.call(nil).should == 'fooa'
        end
      end
    end
  end

  describe "#enhance" do
    it "preserves previous configuration properties" do
      config_from { ui_mode :form }.enhance { portal :NOTIS }.ui_mode.should == :form
    end

    it "sets new configuration properties" do
      config_from { ui_mode :form }.enhance { portal :NOTIS }.portal.should == :NOTIS
    end

    it "overrides repeated configuration properties" do
      config_from { portal :NOTIS }.enhance { portal :eNOTIS }.portal.should == :eNOTIS
    end
  end

  describe "#composite_authority" do
    it "returns a composite authority for the configured authorities" do
      config_from { authorities :static, :static }.composite_authority.authorities.size.should == 2
    end
  end
end

class Aker::Configuration
  describe Slice do
    subject { Slice.new { array << 2 } }
    let(:array) { [1] }

    it 'saves the provided block' do
      subject.contents.should be_a Proc
    end

    it 'is possible to evaluate the block later' do
      subject.contents.call
      array.should == [1, 2]
    end
  end
end
