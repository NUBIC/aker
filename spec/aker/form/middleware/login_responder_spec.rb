require File.expand_path("../../../../spec_helper", __FILE__)
require "rack/test"

module Aker::Form::Middleware
  describe LoginResponder do
    include Rack::Test::Methods

    let(:app) do
      Rack::Builder.new do
        use Aker::Form::Middleware::LoginResponder

        app = lambda do |env|
          [200, {"Content-Type" => "text/html"}, ["Hello"]]
        end

        run app
      end
    end

    let(:login_path) { '/auth/login' }

    let(:configuration) do
      path = login_path;
      Aker::Configuration.new { rack_parameters :login_path => path }
    end

    let(:env) do
      { 'aker.configuration' => configuration }
    end

    it "does not intercept GETs to the login path" do
      get login_path, {}, env

      last_response.should be_ok
      last_response.body.should == "Hello"
    end

    it "does not intercept POSTs to paths that are not the login path" do
      post "/foo", {}, env

      last_response.should be_ok
      last_response.body.should == "Hello"
    end

    describe "#call" do
      let(:warden) { mock }

      before do
        env.update("warden" => warden, "REQUEST_METHOD" => "POST")
      end

      describe "when authentication failed" do
        before do
          warden.stub(:authenticated? => false, :custom_failure! => nil)
        end

        it "renders a 'login failed' message" do
          post login_path, {}, env

          last_response.status.should == 401
          last_response.body.should include("Login failed")
        end
      end

      describe "when authentication succeeded" do
        it "redirects to a given URL" do
          warden.should_receive(:authenticated?).and_return(true)

          post login_path, { :url => "/protected" }, env

          last_response.should be_redirect
          last_response.location.should == "/protected"
        end

        it "redirects to the application's root if no URL was given" do
          warden.should_receive(:authenticated?).and_return(true)
          env['SCRIPT_NAME'] = "/foo"

          post login_path, {}, env

          last_response.should be_redirect
          last_response.location.should == "/foo/"
        end

        it "redirects to the application's root if the URL given is a blank string" do
          warden.should_receive(:authenticated?).and_return(true)

          post login_path, { :url => "" }, env

          last_response.should be_redirect
          last_response.location.should == "/"
        end
      end
    end
  end
end
