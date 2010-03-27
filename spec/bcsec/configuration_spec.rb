require File.expand_path('../../spec_helper', __FILE__)

require 'bcsec/configuration'

describe Bcsec::Configuration do
  before do
    @config = blank_config
  end
  
  def config_from(&block)
    Bcsec::Configuration.new(&block)
  end

  def blank_config
    Bcsec::Configuration.new
  end

  describe "authorities" do
    it "requires at least one" do
      lambda { blank_config.authorities }.should raise_error("No authorities configured")
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

    describe "for authorities" do
      it "can configure an authority from a symbol" do
        config_from { authority :static }.authorities.first.class.should == Bcsec::Authorities::Static
      end

      it "can configure an authority from a string" do
        config_from { authority "static" }.authorities.first.class.should == Bcsec::Authorities::Static
      end

      it "can configure an authority from a symbol with underscores" do
        config_from { authority :all_access }.authorities.first.class.should == Bcsec::Authorities::AllAccess
      end

      it "can configure an authority from a class" do
        config_from { authority Bcsec::Authorities::Static }.authorities.first.class.should == Bcsec::Authorities::Static
      end

      it "can configure an authority from an instance" do
        expected = Object.new
        config_from { authority expected }.authorities.first.should == expected
      end

      it "it passes the configuration to an instantiated authority" do
        actual = config_from { authority Struct.new(:config) }
        actual.authorities.first.config.should == actual
      end

      it "defers instantiating the authorities until the configuration is complete" do
        config_from {
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

    describe "deprecated attribute handling" do
      it "warns when setting app_name"
      it "warns when setting authenticator"
      it "warns when setting authenticators"
      it "passes through the authenticators to authorities"
      it "warns when using the :authenticate_only authenticator"
      it "converts the :authenticate_only authenticator to the :all_access authority"
      it "warns when using the :mock authenticator"
      it "converts the :mock authenticator to the :static authority"
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
end
