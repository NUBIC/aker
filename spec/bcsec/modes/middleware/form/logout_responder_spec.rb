require File.expand_path("../../../../../spec_helper", __FILE__)
require "rack/test"

module Bcsec::Modes::Middleware::Form
  describe LogoutResponder do
    include Rack::Test::Methods

    let(:app) do
      Rack::Builder.new do
        use Bcsec::Modes::Middleware::Form::LogoutResponder
        run lambda { |env| [404, {"Content-Type" => "text/plain"}, []] }
      end
    end

    describe '#call' do
      it "responds to GET /logout" do
        get "/logout"

        last_response.should be_ok
        last_response.content_type.should == "text/html"
      end

      it 'does not respond on other paths' do
        get "/"

        last_response.status.should == 404
      end

      it 'does not respond on other methods' do
        post "/logout"

        last_response.status.should == 404
      end
    end
  end
end
