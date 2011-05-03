require File.expand_path("../../../../../spec_helper", __FILE__)
require "rack/test"

module Bcsec::Modes::Middleware::Form
  describe LogoutResponder do
    include Rack::Test::Methods

    let(:assets) { mock }

    let(:app) do
      a = assets

      Rack::Builder.new do
        use Bcsec::Modes::Middleware::Form::LogoutResponder, a
        run lambda { |env| [404, {"Content-Type" => "text/plain"}, []] }
      end
    end

    describe '#call' do
      it "responds to GET /logout" do
        assets.should_receive(:login_html).
          with(anything, hash_including(:logged_out => true)).
          and_return("logged out")

        get "/logout"

        last_response.should be_ok
        last_response.body.should == 'logged out'
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
