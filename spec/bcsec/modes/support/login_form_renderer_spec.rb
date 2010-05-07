require File.expand_path("../../../../spec_helper", __FILE__)
require "rack"

module Bcsec::Modes::Support
  describe LoginFormRenderer do
    before do
      @env = Rack::MockRequest.env_for("/login")
      @vessel = Object.new
      @vessel.extend(LoginFormRenderer)
    end

    describe '#assets' do
      it "is an attribute accessor" do
        assets = stub

        @vessel.assets = assets

        @vessel.assets.should == assets
      end
    end

    describe "#provide_login_html" do
      before do
        @assets = mock
        @vessel.assets = @assets
      end

      it "renders a login form" do
        @assets.should_receive(:login_html).with(@env).and_return("login html")

        @vessel.provide_login_html(@env).should == "login html"
      end

      it "can pass arguments to the asset provider" do
        @assets.should_receive(:login_html).with(@env, 'arg').and_return("login html with arg")

        @vessel.provide_login_html(@env, 'arg').should == "login html with arg"
      end
    end

    describe "#provide_login_css" do
      before do
        @assets = mock
        @vessel.assets = @assets
      end

      it "renders CSS for the login form" do
        @assets.should_receive(:login_css).and_return("login css")

        @vessel.provide_login_css.should == "login css"
      end
    end
  end
end
