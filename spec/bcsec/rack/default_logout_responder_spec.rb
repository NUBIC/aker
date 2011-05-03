require File.expand_path('../../../spec_helper', __FILE__)

require 'rack/test'

module Bcsec::Rack
  describe DefaultLogoutResponder do
    include Rack::Test::Methods

    let(:path) { '/logout' }

    let(:app) do
      p = path

      Rack::Builder.new do
        use DefaultLogoutResponder, p
        run lambda { |env| [404, {'Content-Type' => 'text/html'}, []] }
      end
    end

    describe '#call' do
      it 'responds to GET /logout' do
        get path

        last_response.status.should == 200
        last_response.body.should == "You have been logged out."
      end

      it 'does not respond to other methods' do
        post path

        last_response.status.should == 404
      end

      it 'does not respond to other paths' do
        get '/'

        last_response.status.should == 404
      end
    end
  end
end
