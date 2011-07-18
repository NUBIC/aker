require File.expand_path('../spec_helper', __FILE__)

require 'aker'

describe Aker do
  before do
    Aker.authority = nil
    Aker.configuration = nil
  end

  after do
    Aker.authority = nil
    Aker.configuration = nil
  end

  describe "::VERSION" do
    it "exists" do
      lambda { Aker::VERSION }.should_not raise_error
    end

    it "has three or four dot-separated parts" do
      Aker::VERSION.split('.').size.should be_between(3, 4)
    end
  end

  describe "configuration" do
    it "can be set directly" do
      Aker.configuration = Aker::Configuration.new { portal :ENU }
      Aker.configuration.portal.should == :ENU
    end

    it "does not accumulate direct set configurations" do
      Aker.configuration = Aker::Configuration.new { api_mode :basic }
      Aker.configuration = Aker::Configuration.new { portal :ENU }
      Aker.configuration.api_modes.should == [] # the default
    end

    it "can be configured using #configure" do
      Aker.configure { portal :ENU }
      Aker.configuration.portal.should == :ENU
    end

    it "accumulates #configure configurations" do
      Aker.configure { api_modes :basic, :cas_proxy }
      Aker.configure { portal :LIMS }
      Aker.configuration.api_modes.should == [:basic, :cas_proxy]
      Aker.configuration.portal.should == :LIMS
    end
  end

  describe "authority" do
    before do
      @auth = Aker::Authorities::Static.new
      @auth.valid_credentials!(:cas, "jo", "ST-12345")
    end

    it "can be set directly" do
      Aker.authority = @auth
      Aker.authority.valid_credentials?(:cas, "ST-12345").should_not be_nil
    end

    it "uses the composite authority from the configuration by default" do
      Aker.configuration = Aker::Configuration.new {
        a = Aker::Authorities::Static.new
        a.valid_credentials!(:magic, "jo", "man")
        authority a
      }
      Aker.configuration.logger = spec_logger
      Aker.authority.valid_credentials?(:magic, "man").username.should == "jo"
    end

    it "prefers a directly-set authority" do
      Aker.configuration = Aker::Configuration.new { authority :static }
      Aker.configuration.logger = spec_logger
      Aker.authority.valid_credentials?(:cas,  "ST-12345").should be_nil
      Aker.authority = @auth
      Aker.authority.valid_credentials?(:cas,  "ST-12345").should_not be_nil
    end
  end
end
