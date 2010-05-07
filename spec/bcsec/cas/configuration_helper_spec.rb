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

    describe "#cas_logout_url" do
      it "is built from the base URL" do
        @actual.cas_logout_url.should == "https://cas.example.org/logout"
      end

      it "uses an explicit one if provided" do
        @config.parameters_for(:cas)[:logout_url] = "https://cas.example.org/exit-point"
        @actual.cas_logout_url.should == "https://cas.example.org/exit-point"
      end
    end

    describe "#cas_base_url" do
      before do
        @config.parameters_for(:cas)[:cas_base_url] = "https://cas2.example.org/"
      end

      it "is preferentially loaded from the :base_url property" do
        @actual.cas_base_url.should == "https://cas.example.org/"
      end

      it "is loaded from the :cas_base_url property if that's all that's provided" do
        @config.parameters_for(:cas)[:base_url] = nil
        @actual.cas_base_url.should == "https://cas2.example.org/"
      end
    end

    describe "#cas_proxy_callback_url" do
      it "is loaded from the :proxy_callback_url property" do
        @config.parameters_for(:cas)[:proxy_callback_url] = "https://cas.example.net/callback/gpgt"
        @actual.cas_proxy_callback_url.should == "https://cas.example.net/callback/gpgt"
      end
    end

    describe "#cas_proxy_retrieval_url" do
      it "is loaded from the :proxy_retrieval_url property" do
        @config.parameters_for(:cas)[:proxy_retrieval_url] = "https://cas.example.net/callback/rpgt"
        @actual.cas_proxy_retrieval_url.should == "https://cas.example.net/callback/rpgt"
      end
    end
  end
end
