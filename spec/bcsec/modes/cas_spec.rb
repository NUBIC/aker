require File.expand_path("../../../spec_helper", __FILE__)
require File.expand_path("a_bcsec_mode", File.dirname(__FILE__))
require 'rack'
require 'uri'

module Bcsec::Modes
  describe Cas do
    before do
      @env = ::Rack::MockRequest.env_for('/')
      @scope = mock
      @mode = Cas.new(@env, @scope)
    end

    it_should_behave_like "a bcsec mode"

    describe "#key" do
      it "is :cas" do
        Cas.key.should == :cas
      end
    end

    describe "#valid?" do
      it "returns false if the ST parameter is not in the query string" do
        @mode.should_not be_valid
      end

      it "returns true if the ticket parameter is in the query string" do
        @env['QUERY_STRING'] = 'ticket=ST-1foo'

        @mode.should be_valid
      end
    end

    describe "#kind" do
      it "is :cas" do
        @mode.kind.should == :cas
      end
    end

    describe "#credentials" do
      before do
        @env["PATH_INFO"] = "/qu/ux"
        @env["QUERY_STRING"] = "foo=baz"
      end

      describe "when there's a service ticket" do
        before do
          @env["QUERY_STRING"] << "&ticket=ST-1foo"
        end

        it "returns two elements" do
          @mode.credentials.size.should == 2
        end

        it "returns the service ticket first" do
          @mode.credentials[0].should == "ST-1foo"
        end

        it "returns the service URL second" do
          @mode.credentials[1].should == "http://example.org/qu/ux?foo=baz"
        end
      end

      it "returns nil if no service ticket was supplied" do
        @mode.credentials.should be_nil
      end
    end

    describe "#authenticate!" do
      before do
        @authority = mock
        @env['bcsec.authority'] = @authority
        @env['QUERY_STRING'] = 'ticket=ST-1foo'
      end

      it "signals success if the service ticket is good" do
        user = stub
        @authority.should_receive(:valid_credentials?).
          with(:cas, 'ST-1foo', "http://example.org/").and_return(user)
        @mode.should_receive(:success!).with(user)

        @mode.authenticate!
      end

      it "does not signal success if the service ticket is bad" do
        @authority.stub!(:valid_credentials? => nil)
        @mode.should_not_receive(:success!)

        @mode.authenticate!
      end
    end

    describe "#on_ui_failure" do
      before do
        @env['bcsec.configuration'] = Bcsec::Configuration.new do
          cas_parameters :login_url => 'https://cas.example.edu/login'
        end
      end

      it "redirects to the CAS server's login page" do
        response = @mode.on_ui_failure
        location = URI.parse(response.location)
        response.should be_redirect

        location.scheme.should == "https"
        location.host.should == "cas.example.edu"
        location.path.should == "/login"
      end

      it "includes the service URL" do
        @env["PATH_INFO"] = "/foo?a=b&c=d"

        actual_uri.query.should == "service=http%3A%2F%2Fexample.org%2Ffoo%3Fa%3Db%26c%3Dd"
      end

      def actual_uri
        response = @mode.on_ui_failure
        URI.parse(response.location)
      end
    end
  end
end
