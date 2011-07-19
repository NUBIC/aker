require File.expand_path('../../../spec_helper', __FILE__)
require 'rack/test'

module Aker::Rack
  describe Logout do
    include Rack::Test::Methods

    let(:path) { '/auth/logout' }

    let(:app) do
      Rack::Builder.new do
        use Aker::Rack::Logout
        run lambda { |env| [200, {'Content-Type' => 'text/html'}, ['from the app']] }
      end
    end

    let(:warden) { stub.as_null_object }

    let(:config) do
      p = path
      Aker::Configuration.new {
        rack_parameters :logout_path => p
      }
    end

    let(:env) do
      {
        'warden' => warden,
        'aker.configuration' => config
      }
    end

    describe '#call' do
      context 'given GET {the configured path}' do
        it 'instructs Warden to log out' do
          warden.should_receive(:logout)

          get path, {}, env
        end

        it 'passes control to the rest of the app' do
          get path, {}, env

          last_response.body.should == 'from the app'
        end
      end

      context 'given GET (some other path)' do
        it 'does not instruct Warden to log out' do
          warden.should_receive(:logout).never

          get '/', {}, env
        end

        it 'passes control to the rest of the app' do
          get '/', {}, env

          last_response.body.should == 'from the app'
        end
      end
    end
  end
end
