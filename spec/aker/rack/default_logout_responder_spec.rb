require File.expand_path('../../../spec_helper', __FILE__)

require 'rack/test'

module Aker::Rack
  describe DefaultLogoutResponder do
    include Rack::Test::Methods

    let(:app) do
      Rack::Builder.new do
        use DefaultLogoutResponder
        run lambda { |env| [404, {'Content-Type' => 'text/html'}, []] }
      end
    end

    let(:configuration) do
      p = path
      Aker::Configuration.new {
        rack_parameters :logout_path => p
      }
    end

    let(:env) do
      { 'aker.configuration' => configuration }
    end

    let(:path) { '/baz/logout' }

    describe '#call' do
      it 'responds to GET {the configured logout path}' do
        get path, {}, env

        last_response.status.should == 200
        last_response.body.should == "You have been logged out."
      end

      it 'does not respond to other methods' do
        post path, {}, env

        last_response.status.should == 404
      end

      it 'does not respond to other paths' do
        get '/', {}, env

        last_response.status.should == 404
      end
    end
  end
end
