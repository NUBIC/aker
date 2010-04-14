require File.expand_path("../../../spec_helper", __FILE__)
require 'rack'

module Bcsec::Modes
  describe Form do
    before do
      @env = Rack::MockRequest.env_for("/")
      @scope = mock
      @mode = Form.new(@env, @scope)

      # Rack::Request manipulations modify the environment in-place
      @request = Rack::Request.new(@env)
    end

    describe "#key" do
      it "is :form" do
        Form.key.should == :form
      end
    end

    describe "#valid?" do
      it "returns true if a username and password are present" do
        @request['username'] = 'foo'
        @request['password'] = 'bar'

        @mode.should be_valid
      end

      it "returns false if a username or password are missing" do
        @mode.should_not be_valid
      end
    end

    describe "#authenticate!" do
      before do
        @request["username"] = "foo"
        @request["password"] = "bar"
        @authority = mock
        @mode.stub!(:authority => @authority)
      end

      it "signals success if the username and password are good" do
        user = stub
        @authority.should_receive(:valid_credentials?).with(:user, "foo", "bar").and_return(user)
        @mode.should_receive(:success!).with(user)

        @mode.authenticate!
      end

      it "does not signal success if the username or password are bad" do
        @authority.stub!(:valid_credentials? => nil)
        @mode.should_not_receive(:success!)

        @mode.authenticate!
      end
    end

    describe "#login_url" do
      it "uses '/login' as its path" do
        URI.parse(@mode.login_url).path.should == "/login"
      end

      it "respects SCRIPT_NAME" do
        @env["SCRIPT_NAME"] = "/app"

        URI.parse(@mode.login_url).path.should == "/app/login"
      end
    end

    describe "#on_ui_failure" do
      it "redirects to the login form" do
        response = @mode.on_ui_failure(@env)

        response.should be_redirect
        URI.parse(response.location).path.should == "/login"
      end
    end
  end
end
