require File.expand_path("../../../../../spec_helper", __FILE__)
require "rack/test"

module Bcsec::Modes::Middleware::Form
  describe LoginResponder do
    include Rack::Test::Methods

    before do
      assets = mock
      login_path = "/login"

      @app = Rack::Builder.new do
        use Bcsec::Modes::Middleware::Form::LoginResponder, login_path, assets
        run lambda { |env| [200, {"Content-Type" => "text/html"}, ["Hello"]] }
      end

      @assets = assets
      @login_path = login_path
    end

    def app
      @app
    end

    it "does not intercept GETs to the login path" do
      get @login_path

      last_response.should be_ok
      last_response.body.should == "Hello"
    end

    it "does not intercept POSTs to paths that are not the login path" do
      post "/foo"

      last_response.should be_ok
      last_response.body.should == "Hello"
    end

    describe "#call" do
      before do
        @warden = mock
        @env = {
          "warden" => @warden,
          "REQUEST_METHOD" => "POST"
        }
      end

      describe "when authentication failed" do
        before do
          @warden.stub(:authenticated? => false, :custom_failure! => nil)
        end

        it "renders a 'login failed' message" do
          @assets.should_receive(:login_html).
            with(hash_including(@env), hash_including({ :login_failed => true })).
            and_return("Login failed")

          post @login_path, {}, @env

          last_response.status.should == 401
          last_response.body.should == "Login failed"
        end

        it "passes the supplied username to the login form renderer" do
          @assets.should_receive(:login_html).
            with(hash_including(@env), hash_including({ :username => "username" })).
            and_return("Login failed")

          post @login_path, {"username" => "username"}, @env
        end

        it "passes the requested resource to the login form renderer" do
          @assets.should_receive(:login_html).
            with(hash_including(@env), hash_including({ :url => "/protected" })).
            and_return("Login failed")

          post @login_path, { :url => "/protected" }, @env
        end
      end

      describe "when authentication succeeded" do
        it "redirects to a given URL" do
          @warden.should_receive(:authenticated?).and_return(true)

          post @login_path, { :url => "/protected" }, @env

          last_response.should be_redirect
          last_response.location.should == "/protected"
        end

        it "redirects to the application's root if no URL was given" do
          @warden.should_receive(:authenticated?).and_return(true)
          @env['SCRIPT_NAME'] = "/foo"

          post @login_path, {}, @env

          last_response.should be_redirect
          last_response.location.should == "/foo/"
        end

        it "redirects to the application's root if the URL given is a blank string" do
          @warden.should_receive(:authenticated?).and_return(true)

          post @login_path, { :url => "" }, @env

          last_response.should be_redirect
          last_response.location.should == "/"
        end
      end
    end
  end
end
