require File.expand_path("../../../spec_helper", __FILE__)
require 'rack'
require 'base64'

module Bcsec::Modes
  describe HttpBasic do
    before do
      @env = Rack::MockRequest.env_for("/")
      @scope = mock
      @mode = HttpBasic.new(@env, @scope)
    end

    describe "#key" do
      it "is :http_basic" do
        HttpBasic.key.should == :http_basic
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

    describe "#scheme" do
      it "returns Basic with a realm" do
        @mode.realm = "Realm"

        @mode.scheme.should == %q{Basic realm="Realm"}
      end
    end

    describe "#authenticate!" do
      before do
        @authority = mock
        @mode.stub!(:authority => @authority)
        @env["HTTP_AUTHORIZATION"] = "Basic " + Base64.encode64("foo:bar")
      end

      it "signals success if the username and password are good" do
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

    describe "#on_ui_failure" do
      it "returns 401 Unauthorized" do
        response = @mode.on_ui_failure(@env)

        response.status.should == 401
      end

      it "returns a WWW-Authenticate header containing the Basic authentication scheme" do
        @mode.realm = "Realm"

        response = @mode.on_ui_failure(@env)
        response.headers['WWW-Authenticate'].should == %q{Basic realm="Realm"}
      end
    end
  end
end
