require File.expand_path("../../../../../spec_helper", __FILE__)
require "rack/test"

module Bcsec::Modes::Middleware::Form
  describe LoginRenderer do
    include Rack::Test::Methods

    let(:app) do
      Rack::Builder.new do
        use Bcsec::Modes::Middleware::Form::LoginRenderer, '/login'
        run lambda { |env| [200, {"Content-Type" => "text/html"}, ["Hello"]] }
      end
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
      get "/login"

      last_response.should be_ok
      last_response.content_type.should == "text/html"
    end

    it 'inserts the redirection URL into the login form' do
      get "/login", { "url" => "http://www.example.edu" }
    end

    it "outputs CSS for GETs on (the login path) + .css" do
      get "/login/login.css"

      last_response.should be_ok
      last_response.content_type.should == "text/css"
    end
  end
end
