require File.expand_path('../../../spec_helper', __FILE__)

module Aker::Rack
  describe Authenticate do
    let(:app) { lambda { |x| x } }

    let(:configuration) do
      Aker::Configuration.new do
        ui_mode :cas
        api_modes :basic, :cas_proxy
      end
    end

    let(:middleware) { Aker::Rack::Authenticate.new(app) }

    let(:env) do
      { "aker.configuration" => configuration, "warden" => warden }
    end

    let(:warden) { mock }

    def call
      middleware.call(env)
    end

    describe "#call" do
      before do
        warden.stub!(:user)
      end

      it "calls the ui mode if interactive" do
        env['aker.interactive'] = true

        warden.should_receive(:authenticate).with(:cas)

        call
      end

      it "calls all the api modes if not interactive" do
        env['aker.interactive'] = false

        warden.should_receive(:authenticate).with(:basic, :cas_proxy)

        call
      end

      it "invokes the app" do
        warden.stub!(:authenticate)

        app.should_receive(:call)

        call
      end
    end

    describe "env['aker.check']" do
      let(:user) { Aker::User.new("jo") }

      before do
        warden.stub!(:user => user, :authenticate => nil)
      end

      let(:facade) { call['aker.check'] }

      it "is a facade" do
        facade.should be_a(Facade)
      end

      it "has the user" do
        facade.user.should == user
      end

      it "has the configuration" do
        facade.configuration.should == configuration
      end
    end
  end
end
