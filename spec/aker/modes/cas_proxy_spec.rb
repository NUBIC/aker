require File.expand_path("../../../spec_helper", __FILE__)
require File.expand_path("a_aker_mode", File.dirname(__FILE__))
require 'rack'

module Aker::Modes
  describe CasProxy do
    before do
      @env = Rack::MockRequest.env_for('/')
      @scope = mock
      @mode = CasProxy.new(@env, @scope)
      @env['aker.configuration'] = Aker::Configuration.new
    end

    it_should_behave_like "a aker mode"

    describe "#key" do
      it "is :cas_proxy" do
        CasProxy.key.should == :cas_proxy
      end
    end

    describe "#kind" do
      it "is :cas_proxy" do
        @mode.kind.should == :cas_proxy
      end
    end

    describe "#credentials" do
      it "finds two credentials" do
        @env["HTTP_AUTHORIZATION"] = "CasProxy PT-1foo"

        @mode.credentials.size.should == 2
      end

      describe "[0]" do
        it "finds a proxy ticket that starts with PT" do
          @env["HTTP_AUTHORIZATION"] = "CasProxy PT-1foo"

          @mode.credentials.first.should == "PT-1foo"
        end

        it "finds a proxy ticket that starts with ST" do
          @env["HTTP_AUTHORIZATION"] = "CasProxy ST-9936-bam"

          @mode.credentials.first.should == "ST-9936-bam"
        end

        it "ignores an out-of-spec proxy ticket" do
          @env["HTTP_AUTHORIZATION"] = "CasProxy MyAttackVector"

          @mode.credentials.should == []
        end

        it "ignores tickets that contain characters not in [^0-9A-Za-z-]" do
          @env["HTTP_AUTHORIZATION"] = "CasProxy ST-@@&%#"

          @mode.credentials.should == []
        end

        it "returns an empty array if no proxy ticket is present" do
          @mode.credentials.should == []
        end
      end

      describe "[1]" do
        it "is the service_url" do
          @env["HTTP_AUTHORIZATION"] = "CasProxy ST-1701"

          @env["SERVER_PORT"] = 80
          @env["SERVER_HOST"] = "example.org"
          @env["rack.url_scheme"] = "http"

          @mode.credentials[1].should == "http://example.org"
        end
      end
    end

    describe "#valid?" do
      it "returns false if there is no authorization header" do
        @mode.should_not be_valid
      end

      it "returns false if the authorization header is for a different scheme" do
        @env["HTTP_AUTHORIZATION"] = "Basic " + Base64.encode64("bas:baz")

        @mode.should_not be_valid
      end

      it "returns true if the authorization header is for CasProxy" do
        @env["HTTP_AUTHORIZATION"] = "CasProxy PT-5-256a"

        @mode.should be_valid
      end
    end

    describe "#scheme" do
      it "returns CasProxy" do
        @mode.scheme.should == "CasProxy"
      end
    end

    describe "#challenge" do
      it "includes the scheme and the realm" do
        @mode.challenge.should == "CasProxy realm=\"Aker\""
      end
    end

    describe "#service_url" do
      before do
        @env["rack.url_scheme"] = "http"
        @env["SERVER_NAME"] = "local.example.net"
        @env["SERVER_PORT"] = "80"
        @env["SCRIPT_NAME"] = "/api"
        @env["PATH_INFO"] = "/people/josephine"
        @env["QUERY_STRING"] = "all=true"
      end

      it "includes the host and script name but not the path info or query string" do
        @mode.service_url.should == "http://local.example.net/api"
      end

      it "prefers the HTTP Host header over the server name and port if present" do
        @env["HTTP_HOST"] = "virtual.example.com:3400"
        @env["SERVER_PORT"] = "8080"
        @mode.service_url.should == "http://virtual.example.com:3400/api"
      end

      it "does not end with a slash if the script name is blank" do
        @env["SCRIPT_NAME"] = ""
        @mode.service_url.should == "http://local.example.net"
      end

      describe "for http" do
        it "does not include the port if it is 80" do
          @mode.service_url.should == "http://local.example.net/api"
        end

        it "includes the port if it isn't 80" do
          @env["SERVER_PORT"] = "3000"
          @mode.service_url.should == "http://local.example.net:3000/api"
        end
      end

      describe "for https" do
        before do
          @env['rack.url_scheme'] = "https"
        end

        it "does not include the port if it is 443" do
          @env["SERVER_PORT"] = "443"
          @mode.service_url.should == "https://local.example.net/api"
        end

        it "includes the port if it isn't 443" do
          @env["SERVER_PORT"] = "3003"
          @mode.service_url.should == "https://local.example.net:3003/api"
        end
      end
    end

    describe "#authenticate!" do
      before do
        @authority = mock
        @mode.stub!(:authority => @authority)
        @env["HTTP_AUTHORIZATION"] = "CasProxy PT-1foo"
      end

      it "signals success if the proxy ticket is good" do
        user = stub
        @authority.should_receive(:valid_credentials?).
          with(:cas_proxy, "PT-1foo", "http://example.org").and_return(user)
        @mode.should_receive(:success!).with(user)

        @mode.authenticate!
      end

      it "does not signal success if the proxy ticket is bad" do
        @authority.stub!(:valid_credentials? => nil)
        @mode.should_not_receive(:success!)

        @mode.authenticate!
      end
    end
  end
end
