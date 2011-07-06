require File.expand_path('../../../spec_helper', __FILE__)

require 'rack/request'
require 'rack/mock'

module Bcsec::Cas
  describe ServiceUrl do
    let(:env) { ::Rack::MockRequest.env_for('/') }

    shared_examples_for '#service_url' do
      it 'is the URL the user was trying to reach' do
        env['PATH_INFO'] = '/qu/ux'
        env['QUERY_STRING'] = 'a=b'
        actual_url.should == 'http://example.org/qu/ux?a=b'
      end

      describe 'with warden\'s "attempted path" in the environment' do
        before do
          set_attempted_path
        end

        it 'uses it if present' do
          env['PATH_INFO'] = '/unauthenticated'

          actual_url.should == 'http://example.org/foo/quux'
        end

        it 'includes the port if not the default for http' do
          env['rack.url_scheme'] = 'http'
          env['SERVER_PORT'] = 81

          actual_url.should == 'http://example.org:81/foo/quux'
        end

        it 'includes the port if not the default for https' do
          env['rack.url_scheme'] = 'https'
          env['SERVER_PORT'] = 80

          actual_url.should == 'https://example.org:80/foo/quux'
        end
      end

      it "filters out a service ticket that's the sole parameter" do
        env['QUERY_STRING'] = 'ticket=ST-foo'
        actual_url.should == 'http://example.org/'
      end

      it "filters out a service ticket that's the first parameter of several" do
        env['QUERY_STRING'] = 'ticket=ST-bar&foo=baz'
        actual_url.should == 'http://example.org/?foo=baz'
      end

      it "filters out a service ticket that's the last parameter of several" do
        env['QUERY_STRING'] = 'foo=baz&ticket=ST-bar'
        actual_url.should == 'http://example.org/?foo=baz'
      end

      it "filters out a service ticket that's in the middle of several" do
        env['QUERY_STRING'] = 'foo=baz&ticket=ST-bar&zazz=quux'
        actual_url.should == 'http://example.org/?foo=baz&zazz=quux'
      end
    end

    context 'when mixed in' do
      it_behaves_like '#service_url'

      class WithRequest
        include ServiceUrl

        attr_reader :request, :env

        def initialize(env)
          @env = env
          @request = Rack::Request.new(env)
        end
      end

      class WithAttemptedPath < WithRequest
        include Bcsec::Modes::Support::AttemptedPath
      end

      let(:with_request_only) { WithRequest.new(env).service_url }
      let(:with_attempted_path) { WithAttemptedPath.new(env).service_url }
      let(:actual_url) { with_attempted_path }

      def set_attempted_path
        env['warden.options'] = { :attempted_path => '/foo/quux' }
      end

      describe 'when the host class does not have an #attempted_path method' do
        it 'does nothing with the attempted path' do
          env['PATH_INFO'] = '/foo/bar'
          set_attempted_path
          with_request_only.should == 'http://example.org/foo/bar'
        end
      end
    end

    context 'when called directly' do
      it_behaves_like '#service_url'

      let(:request) { ::Rack::Request.new(env) }
      let(:actual_url) { ServiceUrl.service_url(request, attempted_path) }

      def attempted_path
        @attempted_path
      end

      def set_attempted_path
        @attempted_path = '/foo/quux'
      end
    end
  end
end
