require File.expand_path("../../../../../spec_helper", __FILE__)
require "rack/test"

module Bcsec::Modes::Middleware::Cas
  describe TicketRemover do
    include Rack::Test::Methods

    let(:app) do
      Rack::Builder.new do
        use Bcsec::Modes::Middleware::Cas::TicketRemover
        run lambda { |env| [404, { "Content-Type" => "text/plain" }, ['Requested content']] }
      end
    end

    let(:env) do
      { }
    end

    describe '#call' do
      it 'does nothing if not authenticated' do
        get '/foo?ticket=ST-45&q=bar', {}, env

        last_response.body.should == 'Requested content'
      end

      it 'does nothing if no ticket is present' do
        get '/foo?q=bar', {}, env

        last_response.body.should == 'Requested content'
      end

      context 'ticket is present and the user is authenticated' do
        before do
          env['bcsec'] = Bcsec::Rack::Facade.new(Bcsec.configuration, Bcsec::User.new('jo'))

          get '/foo?ticket=ST-45&q=bar', {}, env
        end

        it 'sends a permanent redirect' do
          last_response.status.should == 301
        end

        it 'redirects to the same URI without the ticket' do
          last_response.headers['Location'].should == 'http://example.org/foo?q=bar'
        end
      end
    end
  end
end
