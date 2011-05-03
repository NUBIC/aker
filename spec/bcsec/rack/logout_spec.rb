require File.expand_path('../../../spec_helper', __FILE__)
require 'rack/test'

module Bcsec::Rack
  describe Logout do
    include Rack::Test::Methods

    let(:path) { '/logout' }

    let(:app) do
      p = path

      Rack::Builder.new do
        use Bcsec::Rack::Logout, p
        run lambda { |env| [200, {'Content-Type' => 'text/html'}, ['from the app']] }
      end
    end

    let(:warden) { stub.as_null_object }

    let(:env) do
      { 'warden' => warden }
    end

    describe '#call' do
      context 'given GET /logout' do
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
