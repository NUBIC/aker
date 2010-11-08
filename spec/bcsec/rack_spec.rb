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

      def using?(klass)
        self.uses.detect { |cls, params, block| cls == klass }
      end

      alias :find_use_of :using?
    end

    describe ".use_in" do
      before do
        @builder = MockBuilder.new

        Bcsec.configuration = Bcsec::Configuration.new

        Bcsec::Rack.use_in(@builder)
      end

      it "fails with a useful message if there's no configuration" do
        @builder.reset!
        Bcsec.configuration = nil

        lambda { Bcsec::Rack.use_in(@builder) }.
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
          @builder.should be_using(Warden::Manager)
        end

        it "gives the manager the failure app" do
          mock_manager = Class.new do
            attr_accessor :failure_app
          end.new

          _, _, actual_block = @builder.find_use_of(Warden::Manager)
          actual_block.call(mock_manager)

          mock_manager.failure_app.class.should == Bcsec::Rack::Failure
        end
      end

      describe "modifying the Rack stack" do
        before do
          @builder.reset!

          @test_ui = Class.new(Warden::Strategies::Base) do
            def authenticate!; end
            def self.prepend_middleware(builder); builder.use :ui_ware_before; end
            def self.append_middleware(builder); builder.use :ui_ware_after; end
          end

          @test_api_1 = Class.new(Warden::Strategies::Base) do
            def authenticate!; end
            def self.prepend_middleware(builder); builder.use :api_ware_before; end
            def self.append_middleware(builder); builder.use :api_ware_after; end
          end

          @test_api_2 = Class.new(Warden::Strategies::Base) do
            def authenticate!; end
          end

          Warden::Strategies.add(:test_ui, @test_ui)
          Warden::Strategies.add(:test_api_1, @test_api_1)
          Warden::Strategies.add(:test_api_2, @test_api_2)

          Bcsec.configure do
            ui_mode :test_ui
            api_modes :test_api_1, :test_api_2
          end

          Bcsec::Rack.use_in(@builder)

          @bcsec_index = @builder.uses.map { |u| u.first }.index(Bcsec::Rack::Setup)
          @logout_index = @builder.uses.map { |u| u.first }.index(Bcsec::Rack::Logout)
          @bcaudit_index = @builder.uses.map { |u| u.first }.index(Bcaudit::Middleware)
        end

        it "prepends middleware for UI modes first" do
          @builder.uses[0].first.should == :ui_ware_before
        end

        it "prepends middleware for API modes after UI modes" do
          @builder.uses[1].first.should == :api_ware_before
        end

        it "attaches the logout middleware directly after Bcsec::Rack::Setup" do
          @logout_index.should == @bcsec_index + 1
        end

        it "attaches the bcaudit middleware after the logout middleware" do
          @bcaudit_index.should == @logout_index + 1
        end

        it "mounts the logout middleware to /logout" do
          _, args, _ = @builder.uses[@logout_index]

          args.should == ["/logout"]
        end

        it "appends middleware for UI modes directly after the bcaudit middleware" do
          @builder.uses[@bcaudit_index + 1].first.should == :ui_ware_after
        end

        it "appends middleware for API modes after appended UI middleware" do
          @builder.uses[@bcaudit_index + 2].first.should == :api_ware_after
        end

        it "uses middleware for the passed-in configuration instead of the global configuration if present" do
          config = Bcsec::Configuration.new {
            ui_mode :test_ui
          }

          builder = MockBuilder.new
          Bcsec::Rack.use_in(builder, config)

          builder.uses[0].first.should == :ui_ware_before
          builder.uses[1].first.should_not == :api_ware_before
        end
      end

      it "attaches the bcsec middleware" do
        @builder.should be_using(Bcsec::Rack::Setup)
      end

      it "passes on the configuration to the setup middleware if provided" do
        b = MockBuilder.new
        config = Bcsec::Configuration.new { portal :hello }
        Bcsec::Rack.use_in(b, config)
        b.find_use_of(Bcsec::Rack::Setup)[1].first.portal.should == :hello
      end
    end
  end
end
