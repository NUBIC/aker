require File.expand_path("../../../../../spec_helper", __FILE__)
require "rack/test"

module Bcsec::Modes::Middleware::Form
  describe LogoutResponder do
    include Rack::Test::Methods

    let(:app) do
      c = configuration

      Rack::Builder.new do
        use Bcsec::Modes::Middleware::Form::LogoutResponder, c

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

    let(:configuration) { Bcsec::Configuration.new }

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

      context "if :use_custom_logout_page is true" do
        before do
          configuration.add_parameters_for(:form, :use_custom_logout_page => true)
        end

        it "passes GET /logout to the application" do
          get "/logout"

          last_response.body.should == "Logged out"
        end
      end
    end
  end
end
