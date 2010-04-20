require File.expand_path("../../../spec_helper", __FILE__)
require File.expand_path("a_bcsec_mode", File.dirname(__FILE__))
require 'base64'
require 'rack'

module Bcsec::Modes
  describe HttpBasic do
    before do
      @env = ::Rack::MockRequest.env_for("/")
      @scope = mock
      @mode = HttpBasic.new(@env, @scope)
      @env['bcsec.configuration'] = Bcsec::Configuration.new
    end

    it_should_behave_like "a bcsec mode"

    describe "#key" do
      it "is :http_basic" do
        HttpBasic.key.should == :http_basic
      end
    end

    describe "#kind" do
      it "is :user" do
        @mode.kind.should == :user
      end
    end

    describe "#credentials" do
      it "returns username and password given an Authorization header" do
        @env["HTTP_AUTHORIZATION"] = "Basic " + Base64.encode64("foo:bar")

        @mode.credentials.should == ["foo", "bar"]
      end

      it "returns an empty array when no Authorization header is present" do
        @mode.credentials.should == []
      end

      it "returns an empty array when the Authorization header isn't a valid response to a Basic challenge" do
        @env["HTTP_AUTHORIZATION"] = "garbage"

        @mode.credentials.should == []
      end
    end

    describe "#valid?" do
      it "is not valid if the Authorization header is blank" do
        @mode.should_not be_valid
      end

      it "is not valid if the Authorization header does not contain 'Basic'" do
        @env["HTTP_AUTHORIZATION"] = "Fake auth"

        @mode.should_not be_valid
      end

      it "is not valid if the Authorization header contains malformed credentials" do
        @env["HTTP_AUTHORIZATION"] = "Basic :?$"

        @mode.should_not be_valid
      end

      it "is valid if the Authorization header contains 'Basic' followed by base64-encoded credentials" do
        credentials = Base64.encode64("foo:bar")
        @env["HTTP_AUTHORIZATION"] = "Basic #{credentials}"

        @mode.should be_valid
      end
    end

    describe "#authenticate!" do
      before do
        @authority = mock
        @env['bcsec.authority'] = @authority
      end

      it "signals success if the username and password are good" do
        @env["HTTP_AUTHORIZATION"] = "Basic " + Base64.encode64("foo:bar")
        user = stub
        @authority.should_receive(:valid_credentials?).with(:user, 'foo', 'bar').and_return(user)
        @mode.should_receive(:success!).with(user)

        @mode.authenticate!
      end

      it "does not signal success if the username or password are bad" do
        @authority.stub(:valid_credentials? => nil)
        @mode.should_not_receive(:success!)

        @mode.authenticate!
      end
    end

    describe "#realm" do
      it "prefers the portal attribute of the configuration" do
        @env['bcsec.configuration'].portal = "Realm"

        @mode.realm.should == "Realm"
      end

      it "defaults to 'Bcsec'" do
        @mode.realm.should == "Bcsec"
      end
    end

    describe "#scheme" do
      it "returns Basic with a realm" do
        @mode.scheme.should == %q{Basic realm="Bcsec"}
      end
    end

    describe "#on_ui_failure" do
      before do
        @response = @mode.on_ui_failure(@env)
      end

      it "returns 401 Unauthorized" do
        @response.status.should == 401
      end

      it "returns a WWW-Authenticate header containing the Basic authentication scheme" do
        @response.headers['WWW-Authenticate'].should == %q{Basic realm="Bcsec"}
      end
    end
  end
end
