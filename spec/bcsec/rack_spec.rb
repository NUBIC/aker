require File.expand_path('../../spec_helper', __FILE__)

module Bcsec
  describe Rack do
    after do
      ::Warden::Strategies.clear!
    end

    class MockBuilder
      def reset!
        self.uses.clear
      end

      def use(cls, *params, &block)
        self.uses << [cls, params, block]
      end

      def uses
        @uses ||= []
      end

      def using?(klass, *params)
        self.uses.detect { |cls, prms, block| cls == klass && params == prms }
      end

      alias :find_use_of :using?
    end

    describe ".use_in" do
      let(:builder) { MockBuilder.new }
      let(:configuration) { Bcsec::Configuration.new }

      before do
        Bcsec.configuration = configuration

        Bcsec::Rack.use_in(builder)
      end

      it "fails with a useful message if there's no configuration" do
        builder.reset!
        Bcsec.configuration = nil

        lambda { Bcsec::Rack.use_in(builder) }.
          should raise_error(/Please set one or the other before calling use_in./)
      end

      describe "setting up modes" do
        it "installs the form mode" do
          ::Warden::Strategies[:form].should == Bcsec::Modes::Form
        end

        it "installs the basic mode" do
          ::Warden::Strategies[:http_basic].should == Bcsec::Modes::HttpBasic
        end

        it "installs the cas mode" do
          ::Warden::Strategies[:cas].should == Bcsec::Modes::Cas
        end

        it "installs the cas proxy mode" do
          ::Warden::Strategies[:cas_proxy].should == Bcsec::Modes::CasProxy
        end
      end

      describe "configuring warden" do
        it "uses a manager" do
          builder.should be_using(Warden::Manager)
        end

        it "gives the manager the failure app" do
          mock_manager = Class.new do
            attr_accessor :failure_app
          end.new

          _, _, actual_block = builder.find_use_of(Warden::Manager)
          actual_block.call(mock_manager)

          mock_manager.failure_app.class.should == Bcsec::Rack::Failure
        end
      end

      describe "modifying the Rack stack" do
        let(:ui_mode) do
          Class.new(Warden::Strategies::Base) do
            def authenticate!; end
            def self.prepend_middleware(builder, conf); builder.use :ui_ware_before, conf; end
            def self.append_middleware(builder, conf); builder.use :ui_ware_after, conf; end
          end
        end

        let(:api_mode_a) do
          Class.new(Warden::Strategies::Base) do
            def authenticate!; end
            def self.prepend_middleware(builder, conf); builder.use :api_ware_before, conf; end
            def self.append_middleware(builder, conf); builder.use :api_ware_after, conf; end
          end
        end

        let(:api_mode_b) do
          Class.new(Warden::Strategies::Base) do
            def authenticate!; end
          end
        end

        before do
          builder.reset!

          Warden::Strategies.add(:ui_mode, ui_mode)
          Warden::Strategies.add(:api_mode_a, api_mode_a)
          Warden::Strategies.add(:api_mode_b, api_mode_b)

          Bcsec.configure do
            ui_mode :ui_mode
            api_modes :api_mode_a, :api_mode_b
          end

          Bcsec::Rack.use_in(builder)

          @bcsec_index = builder.uses.map { |u| u.first }.index(Bcsec::Rack::Setup)
          @logout_index = builder.uses.map { |u| u.first }.index(Bcsec::Rack::Logout)
          @bcaudit_index = builder.uses.map { |u| u.first }.index(Bcaudit::Middleware)
        end

        it "prepends middleware for UI modes first" do
          builder.uses[0].first.should == :ui_ware_before
        end

        it "prepends middleware for API modes after UI modes" do
          builder.uses[1].first.should == :api_ware_before
        end

        it "passes a configuration object to prepended UI middleware" do
          builder.should be_using(:ui_ware_before, configuration)
        end

        it "passes a configuration object to prepended API middleware" do
          builder.should be_using(:api_ware_before, configuration)
        end

        it "attaches the logout middleware directly after Bcsec::Rack::Setup" do
          @logout_index.should == @bcsec_index + 1
        end

        it "attaches the bcaudit middleware after the logout middleware" do
          @bcaudit_index.should == @logout_index + 1
        end

        it "attaches the default logout responder at the end of the chain" do
          builder.uses.map { |u| u.first }.last.should == Bcsec::Rack::DefaultLogoutResponder
        end

        it "mounts the logout middleware to /logout" do
          _, args, _ = builder.uses[@logout_index]

          args.should == ["/logout"]
        end

        it "appends middleware for UI modes directly after the bcaudit middleware" do
          builder.uses[@bcaudit_index + 1].first.should == :ui_ware_after
        end

        it "appends middleware for API modes after appended UI middleware" do
          builder.uses[@bcaudit_index + 2].first.should == :api_ware_after
        end

        it "passes a configuration object to appended UI middleware" do
          builder.should be_using(:ui_ware_after, configuration)
        end

        it "passes a configuration object to appended API middleware" do
          builder.should be_using(:api_ware_after, configuration)
        end

        it "uses middleware for the passed-in configuration instead of the global configuration if present" do
          config = Bcsec::Configuration.new {
            ui_mode :ui_mode
          }

          builder = MockBuilder.new
          Bcsec::Rack.use_in(builder, config)

          builder.uses[0].first.should == :ui_ware_before
          builder.uses[1].first.should_not == :api_ware_before
        end
      end

      it "attaches the bcsec middleware" do
        builder.should be_using(Bcsec::Rack::Setup, configuration)
      end

      it "passes on the configuration to the setup middleware if provided" do
        b = MockBuilder.new
        config = Bcsec::Configuration.new { portal :hello }

        Bcsec::Rack.use_in(b, config)

        b.should be_using(Bcsec::Rack::Setup, config)
      end
    end
  end
end
