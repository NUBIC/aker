require File.expand_path('../../spec_helper', __FILE__)

module Bcsec
  describe Rack do
    after do
      ::Warden::Strategies.clear!
    end

    describe ".use_in" do
      before do
        @builder = Class.new do
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
        end.new

        Bcsec::Rack.use_in(@builder)
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

      describe "prepending middleware" do
        before do
          @builder.reset!

          @test_ui = Class.new(Warden::Strategies::Base) do
            def authenticate!; end
            def self.prepend_middleware(builder); builder.use :ui_ware; end
          end

          @test_api_1 = Class.new(Warden::Strategies::Base) do
            def authenticate!; end
            def self.prepend_middleware(builder); builder.use :api_ware_1; end
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
        end

        it "prepends middleware for UI modes first" do
          @builder.uses[0].first.should == :ui_ware
        end

        it "prepends middleware for API modes after UI modes" do
          @builder.uses[1].first.should == :api_ware_1
        end
      end

      it "attaches the bcsec middleware" do
        @builder.should be_using(Bcsec::Rack::Setup)
      end
    end
  end
end
