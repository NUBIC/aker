require File.expand_path('../../../spec_helper', __FILE__)

require 'rack/test'

module Aker::Rack
  describe DefaultLogoutResponder do
    include Rack::Test::Methods

    let(:app) do
      Rack::Builder.new do
        use DefaultLogoutResponder
        run lambda { |env|
          if env['PATH_INFO'] == '/missing/logout'
            [404, {'Content-Type' => 'text/html'}, ['missing']]
          elsif env['PATH_INFO'] == '/present/logout'
            [200, {'Content-Type' => 'text/html'}, ['app logout']]
          else
            [200, {'Content-Type' => 'text/html'}, ['app']]
          end
        }
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

    let(:path) { '/missing/logout' }

    describe '#call' do
      it 'responds to GET {the configured logout path} if the application 404s' do
        get path, {}, env

        last_response.status.should == 200
        last_response.body.should == "You have been logged out."
      end

      it "leaves the application's logout response alone if there is one" do
        configuration.parameters_for(:rack)[:logout_path] = '/present/logout'

        get '/present/logout', {}, env

        last_response.status.should == 200
        last_response.body.should == "app logout"
      end

      it 'does not respond to other methods' do
        post path, {}, env

        last_response.body.should == 'missing'
      end

      it 'does not respond to other paths' do
        get '/', {}, env

        last_response.body.should == 'app'
      end
    end
  end
end
