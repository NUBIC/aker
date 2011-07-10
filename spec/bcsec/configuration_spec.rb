require File.expand_path('../../spec_helper', __FILE__)

describe Bcsec::Configuration do
  before do
    @config = blank_config
  end

  def config_from(options={}, &block)
    Bcsec::Configuration.new(options, &block)
  end

  def blank_config
    Bcsec::Configuration.new
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
    class Bcsec::Spec::SomeMode < Bcsec::Modes::Base
      def self.key
        :some
      end
    end

    let(:config) { Bcsec::Configuration.new(:slices => []) }

    it 'registers the mode' do
      config.register_mode Bcsec::Spec::SomeMode

      config.registered_modes.should == [Bcsec::Spec::SomeMode]
    end

    it 'rejects objects that do not have keys' do
      lambda { config.register_mode "No key here" }.
        should raise_error(/"No key here" is not usable as a Bcsec mode/)
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

  describe 'slices' do
    let(:a_slice) { Bcsec::Configuration::Slice.new { portal 'from_slice' } }

    before do
      @original_slices = Bcsec::Configuration.default_slices.dup
      Bcsec::Configuration.default_slices.clear
    end

    after do
      Bcsec::Configuration.default_slices.clear
      Bcsec::Configuration.default_slices.concat(@original_slices)
    end

    describe 'and initialization' do
      before do
        Bcsec::Configuration.add_default_slice a_slice
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
          Bcsec::Configuration.new(:slices => [
              Bcsec::Configuration::Slice.new { ui_mode :form },
              Bcsec::Configuration::Slice.new { api_mode :http_basic }
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
        Bcsec::Configuration.add_default_slice(a_slice)

        Bcsec::Configuration.default_slices.should == [ a_slice ]
      end

      it 'can add a slice from a block' do
        Bcsec::Configuration.add_default_slice {
          portal 'from_default'
        }

        Bcsec::Configuration.default_slices.first.should be_a Bcsec::Configuration::Slice
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
    end

    describe "for authorities" do
      def only_static_config(&block)
        Bcsec::Configuration.new(
          :slices => [Bcsec::Configuration::Slice.new {
            alias_authority :static, Bcsec::Authorities::Static
          }], &block)
      end

      it "can configure an authority from an alias symbol" do
        only_static_config { authority :static }.
          authorities.first.class.should == Bcsec::Authorities::Static
      end

      it "can configure an authority from an alias string" do
        only_static_config { authority "static" }.authorities.first.class.
          should == Bcsec::Authorities::Static
      end

      it 'can configure an authority from an alias to an alias' do
        only_static_config {
          alias_authority :moq, :static
          authority :moq
        }.authorities.first.should be_a Bcsec::Authorities::Static
      end

      it 'fails with a useful message with an unregistered alias' do
        lambda {
          only_static_config { authority :cas }
        }.should raise_error(/Unknown authority alias :cas./)
      end

      it "can configure an authority from a class" do
        only_static_config { authority Bcsec::Authorities::Static }.authorities.first.class.
          should == Bcsec::Authorities::Static
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

    describe "central parameters" do
      before do
        @actual = config_from { central File.expand_path("../bcsec-sample.yml", __FILE__) }
      end

      it "acquires the netid parameters" do
        @actual.parameters_for(:netid)[:'ldap-servers'].should == ["registry.northwestern.edu"]
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

    describe "deprecated attribute handling" do
      it "warns when setting app_name" do
        config_from { app_name "Sammy" }
        deprecation_message.should =~
          /app_name is unnecessary\.  Remove it from your configuration\..*2.2/
      end

      it "warns when setting authenticator" do
        config_from { authenticator :static }
        deprecation_message.should =~
          /authenticator is deprecated\.  Use authority instead\..*2.2/
      end

      it "passes through the authenticator to authorities" do
        config_from { authenticator :static }.authorities.first.class.
          should == Bcsec::Authorities::Static
      end

      it "warns when setting authenticators" do
        config_from { authenticators :static }
        deprecation_message.should =~
          /authenticators is deprecated\.  Use authorities instead\..*2.2/
      end

      it "passes through the authenticators to authorities" do
        config_from { authenticators :static }.authorities.first.class.
          should == Bcsec::Authorities::Static
      end

      it "warns when using the :authenticate_only authenticator" do
        config_from { authenticator :authenticate_only }
        deprecation_message(1).should =~
          /The :authenticate_only authenticator is no longer necessary.  To prevent the portal access check, don't include a portal in the configuration..*2.2/
      end

      it "ignores the :authenticate_only authenticator" do
        config_from { authenticator :static, :authenticate_only }.authorities.size.should == 1
      end

      it "warns when using the :mock authenticator" do
        config_from { authenticator :mock }
        deprecation_message(1).should =~
          /The :mock authenticator is now the :static authority.  Please update your configuration..*2.2/
      end

      it "converts the :mock authenticator to the :static authority" do
        config_from { authenticator :mock }.authorities.first.class.
          should == Bcsec::Authorities::Static
      end

      it "converts a left-over :mock authority to the :static authority" do
        config_from { authority :mock }.authorities.first.class.
          should == Bcsec::Authorities::Static
      end

      it "converts left-over renamed authorities to the new names" do
        config_from { authorities :mock }.authorities.first.class.
          should == Bcsec::Authorities::Static
      end

      it "warns when setting ldap_server" do
        config_from { ldap_server "ldap.nu.edu" }
        deprecation_message.should =~
          /ldap_server is deprecated\.  Use netid_parameters :server => "ldap.nu.edu" instead\..*2.2/
      end

      it "passes through ldap_server to netid_parameters" do
        config_from { ldap_server "ldap.nu.edu" }.
          parameters_for(:netid)[:server].should == "ldap.nu.edu"
      end

      it "warns when setting ldap_username" do
        config_from { ldap_username "cn=joe" }
        deprecation_message.should =~
          /ldap_username is deprecated\.  Use netid_parameters :user => "cn=joe" instead\..*2.2/
      end

      it "passes through ldap_username to netid_parameters" do
        config_from { ldap_username "cn=joe" }.
          parameters_for(:netid)[:user].should == "cn=joe"
      end

      it "warns when setting ldap_password" do
        config_from { ldap_password "joesmom" }
        deprecation_message.should =~
          /ldap_password is deprecated\.  Use netid_parameters :password => "joesmom" instead\..*2.2/
      end

      it "passes through ldap_server to netid_parameters" do
        config_from { ldap_password "joesmom" }.
          parameters_for(:netid)[:password].should == "joesmom"
      end

      it "warns when calling establish_cc_pers_connection" do
        config_from { establish_cc_pers_connection }
        deprecation_message.should =~
          /establish_cc_pers_connection is deprecated\.  Use pers_parameters :separate_connection => true instead\..*2.2/
      end

      it "converts establish_cc_pers_connection to a parameters_for(:pers)" do
        config_from { establish_cc_pers_connection }.
          parameters_for(:pers)[:separate_connection].should be_true
      end

      describe "in use_cas" do
        before do
          @config = config_from do
            cas_parameters :base_url => "https://cas.example.edu"
            use_cas
          end
        end

        it "issues a deprecation warning" do
          deprecation_message.should =~
            /use_cas is deprecated\.  Use api_modes :cas_proxy; ui_mode :cas; authorities :cas instead\..*2.2/
        end

        it "sets up the CAS UI mode" do
          @config.ui_mode.should == :cas
        end

        it "sets up the CAS proxy API mode" do
          @config.api_modes.should == [:cas_proxy]
        end

        it "sets up the CAS authority" do
          @config.authorities.length.should == 1
          @config.authorities.first.class.should == Bcsec::Authorities::Cas
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

class Bcsec::Configuration
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
