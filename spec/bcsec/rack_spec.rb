require File.expand_path('../../spec_helper', __FILE__)

module Bcsec
  describe Rack do
    after do
      ::Warden::Strategies.clear!
    end

    describe ".use_in" do
      before do
        @builder = stub
      end

      def build
        Bcsec::Rack.use_in(@builder)
      end

      describe "setting up modes" do
        before do
          @builder.should_receive(:use).any_number_of_times
          build
        end

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
          @builder.should_receive(:use).with(Warden::Manager)
          build
        end

        it "gives the manager the failure app" do
          pending

          mock_manager = Object.new
          mock_manager.should_receive(:failure_app).with(Bcsec::Rack::Failure)
          @builder.should_receive(:use).with(Warden::Manager).and_yield(mock_manager)
        end
      end

      it "attaches the bcsec middleware" do
        pending

        @builder.should_receive(:use).with(Bcsec::Rack::Setup)
        build
      end
    end
  end
end
