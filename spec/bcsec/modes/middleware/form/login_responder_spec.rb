require File.expand_path("../../../../../spec_helper", __FILE__)
require "rack/test"

module Bcsec::Modes::Middleware::Form
  describe LoginResponder do
    include Rack::Test::Methods

    before do
      assets = mock
      login_path = "/login"

      @app = Rack::Builder.new do
        use LoginResponder, login_path, assets
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
        @warden = stub(:authenticated?)
        @env = Rack::MockRequest.env_for(@login_path)
        @env['warden'] = @warden
        @env['REQUEST_METHOD'] = 'POST'
      end

      it "renders a 'login failed' message if authentication failed" do
        @warden.stub!(:authenticated? => false)
        @assets.should_receive(:login_html).with(anything(), { :show_failure => true }).and_return('Login failed')

        post @login_path, {}, @env

        last_response.status.should == 401
        last_response.body.should == 'Login failed'
      end
      
      it "redirects to the application's root if authentication succeeded" do
        @warden.stub!(:authenticated? => true)
        post @login_path, {}, @env

        last_response.should be_redirect
        last_response.location.should == '/'
      end
    end
  end
end
