require File.expand_path('../../../spec_helper', __FILE__)

module Bcsec::Cas
  describe ConfigurationHelper do
    before do
      @config = Bcsec::Configuration.new
      @config.parameters_for(:cas)[:base_url] = "https://cas.example.org/"
      @actual = Class.new do
        include Bcsec::Cas::ConfigurationHelper

        attr_reader :configuration

        def initialize(config)
          @configuration = config
        end
      end.new(@config)
    end

    describe "#cas_login_url" do
      it "is built from the base URL" do
        @actual.cas_login_url.should == "https://cas.example.org/login"
      end

      it "uses an explicit one if provided" do
        @config.parameters_for(:cas)[:login_url] = "https://cas.example.org/entry-point"
        @actual.cas_login_url.should == "https://cas.example.org/entry-point"
      end
    end
  end
end
