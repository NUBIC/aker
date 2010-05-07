require File.expand_path("../../../spec_helper", __FILE__)
require File.expand_path("a_bcsec_mode", File.dirname(__FILE__))
require "rack"

module Bcsec::Modes
  describe Form do
    before do
      @env = ::Rack::MockRequest.env_for("/")
      @scope = mock
      @mode = Form.new(@env, @scope)

      # Rack::Request manipulations modify the environment in-place
      @request = ::Rack::Request.new(@env)
    end

    it_should_behave_like "a bcsec mode"

    describe "#key" do
      it "is :form" do
        Form.key.should == :form
      end
    end

    describe "#kind" do
      it "is :user" do
        @mode.kind.should == :user
      end
    end

    describe "#credentials" do
      it "contains username and password" do
        @request["username"] = "foo"
        @request["password"] = "bar"

        @mode.credentials.should == ["foo", "bar"]
      end

      it "is an empty array if neither username nor password were given" do
        @mode.credentials.should == []
      end
    end

    describe "#valid?" do
      it "returns true if a username and password are present" do
        @request["username"] = "foo"
        @request["password"] = "bar"

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
        response = @mode.on_ui_failure

        response.should be_redirect
        URI.parse(response.location).path.should == "/login"
      end
    end

    describe "#on_logout" do
      before do
        @mode.assets = mock
      end

      it "renders the login form" do
        @mode.assets = stub(:login_html => 'login form')

        response = @mode.on_logout

        response.status.should == 200
        response.body.should == ['login form']
      end

      it "renders a notification in the form" do
        @mode.assets.should_receive(:login_html).with(hash_including(@env), { :logged_out => true }).and_return([])

        @mode.on_logout
      end
    end
  end
end
