require File.expand_path('../../../spec_helper', __FILE__)

module Bcsec::Rack
  describe Setup do
    before do
      @app = stub()
      @app.stub(:call)
      @user = Bcsec::User.new("jo")

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
      warden.stub(:user).and_return(@user)

      {
        'warden' => warden
      }.merge(base)
    end

    describe "env['bcsec.configuration']" do
      it "is the global configuration by default" do
        Bcsec.configure { portal :NOTIS }
        env = call
        env['bcsec.configuration'].portal.should == :NOTIS
      end

      it "is an explicitly-passed configuration if provided" do
        config = Bcsec::Configuration.new { portal :local }
        Bcsec.configure { portal :global }
        @actual = Setup.new(@app, config)
        env = call
        env['bcsec.configuration'].portal.should == :local
      end
    end

    describe "env['bcsec.authority']" do
      it "is the global authority by default" do
        Bcsec.authority = Object.new
        env = call
        env['bcsec.authority'].object_id.should == Bcsec.authority.object_id
      end

      it "is the local configuration-derived authority if there's a local configuration" do
        config = Bcsec::Configuration.new
        expected_authority = Object.new
        config.should_receive(:composite_authority).and_return(expected_authority)

        @actual = Setup.new(@app, config)
        env = call
        env['bcsec.authority'].object_id.should == expected_authority.object_id
      end

      it "is the explicitly provided authority if there is one" do
        expected_authority = Object.new

        @actual = Setup.new(@app, Bcsec::Configuration.new, expected_authority)
        env = call
        env['bcsec.authority'].object_id.should == expected_authority.object_id
      end
    end

    describe "determining whether to use interactive mode" do
      it "sets the result of the decision as 'bcsec.interactive'" do
        env = call
        env.should have_key("bcsec.interactive")
      end

      it "is always interactive if the accept header includes text/html" do
        env = call("HTTP_ACCEPT" =>
                   "application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5")
        env['bcsec.interactive'].should be_true
      end

      describe "when there are any API modes" do
        before do
          Bcsec.configure {
            api_mode :http_basic
          }
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

      describe "when there are no API modes" do
        it "is interactive if the accept header does not include text/html" do
          env = call("HTTP_ACCEPT" => "*/*")
          env['bcsec.interactive'].should be_true
        end

        it "is interactive if there is no accept header" do
          env = call
          env['bcsec.interactive'].should be_true
        end
      end
    end

    describe "invoking authentication" do
      before do
        Bcsec.configure {
          ui_mode :cas
          api_modes :basic, :cas_proxy
        }
        @warden = Object.new
        @warden.stub(:user)
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
    end

    describe "env['bcsec']" do
      before do
        @actual_facade = call['bcsec']
      end

      it "is a facade" do
        @actual_facade.class.should == Facade
      end

      it "has the user" do
        @actual_facade.user.username.should == "jo"
      end

      it "has the configuration" do
        Bcsec.configure { portal :NOTIS }
        @actual_facade.configuration.portal.should == :NOTIS
      end
    end

    it "always invokes the app" do
      @app.should_receive(:call).and_return([:foo])

      @actual.call(min_env).should == [:foo]
    end
  end
end
