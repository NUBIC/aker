require File.expand_path('../../spec_helper', __FILE__)

module Bcsec
  describe Rack do
    after do
      ::Warden::Strategies.clear!
    end

    describe ".use_in" do
      before do
        @builder = Class.new do
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

      it "attaches the bcsec middleware" do
        @builder.should be_using(Bcsec::Rack::Setup)
      end
    end
  end
end
