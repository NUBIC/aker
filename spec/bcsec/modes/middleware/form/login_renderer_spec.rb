require File.expand_path("../../../../../spec_helper", __FILE__)
require "rack/test"

module Bcsec::Modes::Middleware::Form
  describe LoginRenderer do
    include Rack::Test::Methods

    before(:all) do
      assets = mock

      @app = Rack::Builder.new do
        use LoginRenderer, '/login', assets
        run lambda { |env| [200, {"Content-Type" => "text/html"}, ["Hello"]] }
      end

      @assets = assets
    end

    def app
      @app
    end

    it "does not intercept POSTs to the login path" do
      post "/login"

      last_response.should be_ok
      last_response.body.should == "Hello"
    end

    it "does not intercept GETs to paths that are not the login path" do
      get "/foo"

      last_response.should be_ok
      last_response.body.should == "Hello"
    end

    it "renders login forms for GETs on the login path" do
      @assets.should_receive(:login_html).with(hash_including("SCRIPT_NAME")).and_return("login form")

      get "/login"

      last_response.should be_ok
      last_response.content_type.should == "text/html"
      last_response.body.should == "login form"
    end

    it "outputs CSS for GETs on (the login path) + .css" do
      @assets.should_receive(:login_css).and_return("login css")

      get "/login/login.css"

      last_response.should be_ok
      last_response.content_type.should == "text/css"
      last_response.body.should == "login css"
    end
  end
end
