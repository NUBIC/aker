require File.expand_path("../../../../../spec_helper", __FILE__)
require "rack/test"

module Bcsec::Modes::Middleware::Form
  describe LoginResponder do
    include Rack::Test::Methods

    let(:app) do
      Rack::Builder.new do
        use Bcsec::Modes::Middleware::Form::LoginResponder, '/login'
        run lambda { |env| [200, {"Content-Type" => "text/html"}, ["Hello"]] }
      end
    end

    it "does not intercept GETs to the login path" do
      get '/login'

      last_response.should be_ok
      last_response.body.should == "Hello"
    end

    it "does not intercept POSTs to paths that are not the login path" do
      post "/foo"

      last_response.should be_ok
      last_response.body.should == "Hello"
    end

    describe "#call" do
      let(:env) do
        {
          "warden" => @warden,
          "REQUEST_METHOD" => "POST"
        }
      end

      before do
        @warden = mock
      end

      describe "when authentication failed" do
        before do
          @warden.stub(:authenticated? => false, :custom_failure! => nil)
        end

        it "renders a 'login failed' message" do
          post '/login', {}, env

          last_response.status.should == 401
          last_response.body.should include("Login failed")
        end
      end

      describe "when authentication succeeded" do
        it "redirects to a given URL" do
          @warden.should_receive(:authenticated?).and_return(true)

          post '/login', { :url => "/protected" }, env

          last_response.should be_redirect
          last_response.location.should == "/protected"
        end

        it "redirects to the application's root if no URL was given" do
          @warden.should_receive(:authenticated?).and_return(true)
          env['SCRIPT_NAME'] = "/foo"

          post '/login', {}, env

          last_response.should be_redirect
          last_response.location.should == "/foo/"
        end

        it "redirects to the application's root if the URL given is a blank string" do
          @warden.should_receive(:authenticated?).and_return(true)

          post '/login', { :url => "" }, env

          last_response.should be_redirect
          last_response.location.should == "/"
        end
      end
    end
  end
end
