require File.expand_path("../../../../spec_helper", __FILE__)
require "rack/test"

module Aker::Cas::Middleware
  describe LogoutResponder do
    include Rack::Test::Methods

    let(:app) do
      Rack::Builder.new do
        use Aker::Cas::Middleware::LogoutResponder
        run lambda { |env| [404, { "Content-Type" => "text/plain" }, []] }
      end
    end

    let(:configuration) do
      Aker::Configuration.new.enhance do
        cas_parameters :logout_url => 'https://cas.example.edu/logout'
      end
    end

    let(:env) do
      { 'aker.configuration' => configuration }
    end

    describe '#call' do
      it 'redirects to the CAS logout URL on GET /logout' do
        get "/logout", {}, env

        last_response.should be_redirect
        last_response.location.should == 'https://cas.example.edu/logout'
      end

      it "does not respond to other paths" do
        get "/", {}, env

        last_response.status.should == 404
      end

      it "does not respond to other methods" do
        post "/logout", {}, env

        last_response.status.should == 404
      end
    end
  end
end