require File.expand_path("../../../../spec_helper", __FILE__)
require "rack/test"

module Aker::Cas::Middleware
  describe TicketRemover do
    include Rack::Test::Methods

    let(:app) do
      Rack::Builder.new do
        use Aker::Cas::Middleware::TicketRemover
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

      context 'with ticket and successful authentication' do
        shared_examples_for 'a ticket cleaner' do |method|
          before do
            env['aker.check'] = Aker::Rack::Facade.new(Aker.configuration, Aker::User.new('jo'))

            send(method, '/foo?ticket=ST-45&q=bar', {}, env)
          end

          it 'sends a permanent redirect' do
            last_response.status.should == 301
          end

          it 'redirects to the same URI without the ticket' do
            last_response.headers['Location'].should == 'http://example.org/foo?q=bar'
          end

          it 'has Content-Type text/html' do
            last_response.headers['Content-Type'].should == 'text/html'
          end
        end

        context 'on GET' do
          it_should_behave_like 'a ticket cleaner', :get do
            it 'has a link to the cleaned URI in its body' do
              last_response.body.should == %q{<a href="http://example.org/foo?q=bar">Click here to continue</a>}
            end
          end
        end

        context 'on HEAD' do
          it_should_behave_like 'a ticket cleaner', :head do
            it 'has an empty body' do
              last_response.body.should be_empty
            end
          end
        end
      end
    end
  end
end
