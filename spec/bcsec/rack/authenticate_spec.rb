require File.expand_path('../../../spec_helper', __FILE__)

module Bcsec::Rack
  describe Authenticate do
    let(:app) { lambda { |x| x } }

    let(:configuration) do
      Bcsec::Configuration.new do
        ui_mode :cas
        api_modes :basic, :cas_proxy
      end
    end

    let(:middleware) { Bcsec::Rack::Authenticate.new(app) }

    let(:env) do
      { "bcsec.configuration" => configuration, "warden" => warden }
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
        env['bcsec.interactive'] = true

        warden.should_receive(:authenticate).with(:cas)

        call
      end

      it "calls all the api modes if not interactive" do
        env['bcsec.interactive'] = false

        warden.should_receive(:authenticate).with(:basic, :cas_proxy)

        call
      end

      it "invokes the app" do
        warden.stub!(:authenticate)

        app.should_receive(:call)

        call
      end
    end

    describe "env['bcsec']" do
      let(:user) { Bcsec::User.new("jo") }

      before do
        warden.stub!(:user => user, :authenticate => nil)
      end

      let(:facade) { call['bcsec'] }

      it "is a facade" do
        facade.should be_is_a(Facade)
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
