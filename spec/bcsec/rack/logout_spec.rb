require File.expand_path('../../../spec_helper', __FILE__)
require 'rack/test'

module Bcsec::Rack
  describe Logout do
    include Rack::Test::Methods

    attr_accessor :app

    before do
      @scope = :default
      @warden = stub.as_null_object
      @path = "/logout"
      @env = ::Rack::MockRequest.env_for(@path)
      @env["warden"] = @warden
      @env["bcsec.interactive"] = false
      @env["bcsec.configuration"] = stub.as_null_object

      @mode_with_logout = Class.new(Warden::Strategies::Base) do
        def authenticate!; end
        def on_logout; Rack::Response.new('custom logout response'); end
      end

      @mode_without_logout = Class.new(Warden::Strategies::Base) do
        def authenticate!; end
      end

      Warden::Strategies.add(:mode_with_logout, @mode_with_logout)
      Warden::Strategies.add(:mode_without_logout, @mode_without_logout)

      self.app = Rack::Builder.new do
        use Logout, "/logout"
        run lambda { |env| [200, {'Content-Type' => 'text/html'}, []] }
      end
    end

    after do
      Warden::Strategies.clear!
    end

    it "instructs warden to log out" do
      @warden.should_receive(:logout)

      get @path, {}, @env
    end

    it "calls the UI mode's on_logout method if the request is interactive" do
      @env["bcsec.interactive"] = true
      @env["bcsec.configuration"].stub!(:ui_mode => :mode_with_logout)

      get @path, {}, @env

      last_response.body.should == "custom logout response"
    end

    it "provides a default response if the request is noninteractive" do
      @env["bcsec.interactive"] = false

      get @path, {}, @env

      last_response.status.should == 200
      last_response.body.should == "You have been logged out."
    end

    it "provides a default response if the UI mode does not implement a custom response" do
      @env["bcsec.interactive"] = true
      @env["bcsec.configuration"].stub!(:ui_mode => :mode_without_logout)

      get @path, {}, @env

      last_response.status.should == 200
      last_response.body.should == "You have been logged out."
    end
  end
end
