require File.expand_path('../../../spec_helper', __FILE__)

require 'rack/test'

module Bcsec::Rack
  describe DefaultLogoutResponder do
    include Rack::Test::Methods

    let(:app) do
      p = path

      Rack::Builder.new do
        use DefaultLogoutResponder, p
        run lambda { |env| [404, {'Content-Type' => 'text/html'}, []] }
      end
    end

    let(:configuration) { Bcsec::Configuration.new }

    let(:env) do
      { 'bcsec.configuration' => configuration }
    end

    let(:path) { '/logout' }

    describe '#call' do
      it 'responds to GET /logout' do
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

      context "if :use_custom_logout_page is true" do
        before do
          configuration.add_parameters_for(:rack, :use_custom_logout_page => true)
        end

        it "passes GET /logout to the application" do
          get "/logout", {}, env

          last_response.status.should == 404
        end
      end
    end
  end
end
