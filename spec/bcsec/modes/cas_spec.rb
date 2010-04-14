require File.expand_path("../../../spec_helper", __FILE__)
require 'rack'
require 'uri'

module Bcsec::Modes
  describe Cas do
    before do
      @env = Rack::MockRequest.env_for('/')
      @scope = mock
      @mode = Cas.new(@env, @scope)
    end

    describe "#key" do
      it "is :cas" do
        Cas.key.should == :cas
      end
    end

    describe "#valid?" do
      it "returns false if the ST parameter is not in the query string" do
        @mode.should_not be_valid
      end

      it "returns true if the ST parameter is in the query string" do
        @env['QUERY_STRING'] = 'ST=ST-1foo'

        @mode.should be_valid
      end
    end

    describe "#authenticate!" do
      before do
        @authority = mock
        @mode.stub!(:authority => @authority)
        @env['QUERY_STRING'] = 'ST=ST-1foo'
      end

      it "signals success if the service ticket is good" do
        user = stub
        @authority.should_receive(:valid_credentials?).with(:cas, 'ST-1foo').and_return(user)
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
        @mode.cas_login_url = "https://cas.example.edu/login"
      end

      it "redirects to the CAS server's login page" do
        response = @mode.on_ui_failure(@env)
        location = URI.parse(response.location)
        response.should be_redirect

        location.scheme.should == "https"
        location.host.should == "cas.example.edu"
        location.path.should == "/login"
      end

      it "uses the URL the user was trying to reach as the CAS service URL" do
        @env["PATH_INFO"] = "/foo/bar"

        response = @mode.on_ui_failure(@env)
        location = URI.parse(response.location)

        location.query.should == "service=http://example.org/foo/bar"
      end
    end
  end
end
