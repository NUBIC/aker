require File.expand_path("../../../../spec_helper", __FILE__)
require "rack/test"

module Aker::Form::Middleware
  describe LogoutResponder do
    include Rack::Test::Methods

    let(:app) do
      Rack::Builder.new do
        use Aker::Form::Middleware::LogoutResponder

        app = lambda do |env|
          if env["REQUEST_METHOD"] == "GET" && env["PATH_INFO"] == "/logout"
            [200, {"Content-Type" => "text/plain"}, ["Logged out"]]
          else
            [404, {"Content-Type" => "text/plain"}, []]
          end
        end

        run app
      end
    end

    let(:configuration) { Aker::Configuration.new }

    let(:env) do
      { 'aker.configuration' => configuration }
    end

    describe '#call' do
      it "responds to GET /logout" do
        get "/logout", {}, env

        last_response.should be_ok
        last_response.content_type.should == "text/html"
      end

      it 'does not respond on other paths' do
        get "/", {}, env

        last_response.status.should == 404
      end

      it 'does not respond on other methods' do
        post "/logout", {}, env

        last_response.status.should == 404
      end
    end
  end
end
