require File.expand_path('../spec_helper', __FILE__)

require 'bcsec'

describe Bcsec do
  before do
    Bcsec.authority = nil
    Bcsec.configuration = nil
  end

  describe "::VERSION" do
    it "exists" do
      lambda { Bcsec::VERSION }.should_not raise_error
    end

    it "has three or four dot-separated parts" do
      Bcsec::VERSION.split('.').size.should be_between(3, 4)
    end
  end

  describe "configuration" do
    it "can be set directly" do
      Bcsec.configuration = Bcsec::Configuration.new { portal :ENU }
      Bcsec.configuration.portal.should == :ENU
    end

    it "does not accumulate direct set configurations" do
      Bcsec.configuration = Bcsec::Configuration.new { api_mode :basic }
      Bcsec.configuration = Bcsec::Configuration.new { portal :ENU }
      Bcsec.configuration.api_modes.should == [] # the default
    end

    it "can be configured using #configure" do
      Bcsec.configure { portal :ENU }
      Bcsec.configuration.portal.should == :ENU
    end

    it "accumulates #configure configurations" do
      Bcsec.configure { api_modes :basic, :cas_proxy }
      Bcsec.configure { portal :LIMS }
      Bcsec.configuration.api_modes.should == [:basic, :cas_proxy]
      Bcsec.configuration.portal.should == :LIMS
    end
  end

  describe "authority" do
    before do
      @auth = Bcsec::Authorities::Static.new
      @auth.valid_credentials!(:cas, "jo", "ST-12345")
    end

    it "can be set directly" do
      Bcsec.authority = @auth
      Bcsec.authority.valid_credentials?(:cas, "ST-12345").should_not be_nil
    end

    it "uses the composite authority from the configuration by default" do
      Bcsec.configuration = Bcsec::Configuration.new {
        a = Bcsec::Authorities::Static.new
        a.valid_credentials!(:magic, "jo", "man")
        authority a
      }
      Bcsec.authority.valid_credentials?(:magic, "man").username.should == "jo"
    end

    it "prefers a directly-set authority" do
      Bcsec.configuration = Bcsec::Configuration.new { authority :static }
      Bcsec.authority.valid_credentials?(:cas,  "ST-12345").should be_nil
      Bcsec.authority = @auth
      Bcsec.authority.valid_credentials?(:cas,  "ST-12345").should_not be_nil
    end
  end
end
