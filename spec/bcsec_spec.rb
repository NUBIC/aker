require File.expand_path('../spec_helper', __FILE__)

require 'bcsec'

describe Bcsec do
  before do
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
end
