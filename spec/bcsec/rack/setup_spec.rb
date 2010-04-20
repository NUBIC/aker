require File.expand_path('../../../spec_helper', __FILE__)

module Bcsec::Rack
  describe Setup do
    before do
      @app = stub()
      @app.stub(:call)

      @actual = Setup.new(@app)
      Bcsec.configure { } # defaults
    end

    after do
      Bcsec.configuration = nil
      Bcsec.authority = nil
    end

    def call(env={})
      env = min_env(env)
      @actual.call(env)
      env
    end

    def min_env(base={})
      warden = Object.new
      warden.stub(:authenticate)

      {
        'warden' => warden
      }.merge(base)
    end

    it "adds the configuration to the environment as 'bcsec.configuration'" do
      Bcsec.configure { portal :NOTIS }
      env = call
      env['bcsec.configuration'].portal.should == :NOTIS
    end

    it "adds the configured authority to the environment as 'bcsec.authority'" do
      Bcsec.authority = Object.new
      env = call
      env['bcsec.authority'].object_id.should == Bcsec.authority.object_id
    end

    describe "determining whether to use interactive mode" do
      it "sets the result of the decision as 'bcsec.interactive'" do
        env = call
        env.should have_key("bcsec.interactive")
      end

      it "is interactive if the accept header includes text/html" do
        env = call("HTTP_ACCEPT" =>
                   "application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5")
        env['bcsec.interactive'].should be_true
      end

      it "is not interactive if the accept header does not include text/html" do
        env = call("HTTP_ACCEPT" => "*/*")
        env['bcsec.interactive'].should be_false
      end

      it "is not interactive if there is no accept header" do
        env = call
        env['bcsec.interactive'].should be_false
      end
    end

    describe "invoking authentication" do
      before do
        Bcsec.configure {
          ui_mode :cas
          api_modes :basic, :cas_proxy
        }
        @warden = Object.new
        @env = {
          'warden' => @warden
        }
      end

      it "calls the ui mode if interactive" do
        @warden.should_receive(:authenticate).with(:cas)

        call(@env.merge("HTTP_ACCEPT" => "text/html"))
      end

      it "calls all the api modes if not interactive" do
        @warden.should_receive(:authenticate).with(:basic, :cas_proxy)

        call(@env.merge("HTTP_ACCEPT" => "application/json"))
      end

      it "calls the ui mode if not interactive and there are no api modes" do
        Bcsec.configuration = nil
        Bcsec.configure { ui_mode :form }

        @warden.should_receive(:authenticate).with(:form)

        call(@env.merge("HTTP_ACCEPT" => "application/xml"))
      end
    end

    it "always invokes the app" do
      @app.should_receive(:call).and_return([:foo])

      @actual.call(min_env).should == [:foo]
    end
  end
end
