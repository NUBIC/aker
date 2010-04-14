require File.expand_path("../../../../spec_helper", __FILE__)
require "rack/test"

module Bcsec::Modes::Middleware
  describe Form do
    include Rack::Test::Methods

    before(:all) do
      assets = mock

      @app = Rack::Builder.new do
        use Bcsec::Modes::Middleware::Form, assets
        run lambda { |env| [200, {"Content-Type" => "text/html"}, ["Hello"]] }
      end

      @assets = assets
    end

    def app
      @app
    end

    it "does not intercept GETs to paths that are not the login path" do
      get "/foo"

      last_response.should be_ok
      last_response.body.should == 'Hello'
    end

    it "renders login forms for GETs on the login path" do
      @assets.stub!(:login_html => ['login form'])

      get "/"

      last_response.should be_ok
      last_response.content_type.should == 'text/html'
      last_response.body.should == 'login form'
    end

    it "outputs CSS for GETs on (the login path) + .css" do
      @assets.stub!(:login_css => ['login css'])

      get "/login.css"

      last_response.should be_ok
      last_response.content_type.should == 'text/css'
      last_response.body.should == 'login css'
    end
  end
end
