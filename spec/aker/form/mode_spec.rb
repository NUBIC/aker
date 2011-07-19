require File.expand_path("../../../spec_helper", __FILE__)
require File.expand_path("../../modes/a_aker_mode", __FILE__)
require "rack"

module Aker::Form
  describe Mode do
    let(:config) { Aker::Configuration.new(:slices => [Aker::Rack::Slice.new]) }

    before do
      @env = ::Rack::MockRequest.env_for("/")
      @env['aker.configuration'] = config
      @scope = mock
      @mode = Mode.new(@env, @scope)
    end

    it_should_behave_like "a aker mode"

    describe "#key" do
      it "is :form" do
        Mode.key.should == :form
      end
    end

    describe "#kind" do
      it "is :user" do
        @mode.kind.should == :user
      end
    end

    describe "#credentials" do
      it "contains username and password" do
        set_params("username" => "foo", "password" => "bar")

        @mode.credentials.should == ["foo", "bar"]
      end

      it "is an empty array if neither username nor password were given" do
        @mode.credentials.should == []
      end
    end

    describe "#valid?" do
      it "returns true if a username and password are present" do
        set_params("username" => "foo", "password" => "bar")

        @mode.should be_valid
      end

      it "returns false if a username or password are missing" do
        @mode.should_not be_valid
      end
    end

    describe "#authenticate!" do
      before do
        set_params("username" => "foo", "password" => "bar")

        @authority = mock
        @mode.stub!(:authority => @authority)
      end

      it "signals success if the username and password are good" do
        user = stub
        @authority.should_receive(:valid_credentials?).with(:user, "foo", "bar").and_return(user)
        @mode.should_receive(:success!).with(user)

        @mode.authenticate!
      end

      it "does not signal success if the username or password are bad" do
        @authority.stub!(:valid_credentials? => nil)
        @mode.should_not_receive(:success!)

        @mode.authenticate!
      end
    end

    describe "#login_url" do
      it "uses '/login' as its path" do
        URI.parse(@mode.login_url).path.should == "/login"
      end

      it "respects SCRIPT_NAME" do
        @env["SCRIPT_NAME"] = "/app"

        URI.parse(@mode.login_url).path.should == "/app/login"
      end

      it 'uses another path if one is specified in the configuration' do
        @env['SCRIPT_NAME'] = '/banjo'
        config.parameters_for(:rack)[:login_path] = '/auth/login'

        URI.parse(@mode.login_url).path.should == "/banjo/auth/login"
      end
    end

    describe "#on_ui_failure" do
      include Rack::Utils

      it "redirects to the login form" do
        response = @mode.on_ui_failure

        response.should be_redirect
        URI.parse(response.location).path.should == "/login"
      end

      it 'redirects to a different login form path if specified in the configuration' do
        config.parameters_for(:rack)[:login_path] = '/auth/login'
        response = @mode.on_ui_failure

        URI.parse(response.location).path.should == '/auth/login'
      end

      it "puts the URL the user was trying to reach in the query string" do
        @env["warden.options"] = { :attempted_path => "http://www.example.edu" }

        response = @mode.on_ui_failure

        URI.parse(response.location).query.should == "url=" + escape("http://www.example.edu")
      end
    end

    def set_params(params)
      @env.update(::Rack::MockRequest.env_for("/", :params => params))
    end
  end
end
