require File.expand_path("../../../../../spec_helper", __FILE__)
require "rack/test"

module Bcsec::Modes::Middleware::Cas
  describe LogoutResponder do
    include Rack::Test::Methods

    let(:configuration) do
      Bcsec::Configuration.new.enhance do
        cas_parameters :logout_url => 'https://cas.example.edu/logout'
      end
    end

    let(:app) do
      c = configuration

      Rack::Builder.new do
        use Bcsec::Modes::Middleware::Cas::LogoutResponder, c
        run lambda { |env| [404, { "Content-Type" => "text/plain" }, []] }
      end
    end

    describe '#call' do
      it 'redirects to the CAS logout URL on GET /logout' do
        get "/logout"

        last_response.should be_redirect
        last_response.location.should == 'https://cas.example.edu/logout'
      end

      it "does not respond to other paths" do
        get "/"

        last_response.status.should == 404
      end

      it "does not respond to other methods" do
        post "/logout"

        last_response.status.should == 404
      end
    end
  end
end
