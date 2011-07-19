require File.expand_path('../../spec_helper', __FILE__)

module Aker
  describe Rack do
    after do
      ::Warden::Strategies.clear!
    end

    describe ".use_in" do
      let(:builder) { Aker::Spec::MockBuilder.new }
      let(:configuration) { Aker::Configuration.new(:slices => []) }

      before do
        Aker.configuration = configuration

        Aker::Rack.use_in(builder)
      end

      it "fails with a useful message if there's no configuration" do
        builder.reset!
        Aker.configuration = nil

        lambda { Aker::Rack.use_in(builder) }.
          should raise_error(/Please set one or the other before calling use_in./)
      end

      describe "setting up modes" do
        before do
          configuration.register_mode Aker::Modes::HttpBasic

          builder.reset!
          Aker::Rack.use_in(builder)
        end

        it 'installs the modes registered in the configuration' do
          ::Warden::Strategies[:http_basic].should == Aker::Modes::HttpBasic
        end

        it 'does not install other modes just because they exist' do
          ::Warden::Strategies[:cas].should be_nil
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

          mock_manager.failure_app.class.should == Aker::Rack::Failure
        end
      end

      describe "modifying the Rack stack" do
        let(:ui_mode) do
          Class.new(Warden::Strategies::Base) do
            def authenticate!; end
            def self.prepend_middleware(builder); builder.use :ui_ware_before; end
            def self.append_middleware(builder); builder.use :ui_ware_after; end
          end
        end

        let(:api_mode_a) do
          Class.new(Warden::Strategies::Base) do
            def authenticate!; end
            def self.prepend_middleware(builder); builder.use :api_ware_before; end
            def self.append_middleware(builder); builder.use :api_ware_after; end
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

          config = Aker::Configuration.new(:slices => []) do
            ui_mode :ui_mode
            api_modes :api_mode_a, :api_mode_b

            before_authentication_middleware do |builder|
              builder.use :global_before
            end

            after_authentication_middleware do |builder|
              builder.use :global_after
            end
          end

          Aker::Rack.use_in(builder, config)

          @indexes = builder.uses.each_with_index.map { |u, i| [u.first, i] }.
            inject({}) { |h, (mw, i)| h[mw] = i; h }
          @logout_index = @indexes[Aker::Rack::Logout]
          @session_timer_index = @indexes[Aker::Rack::SessionTimer]
        end

        it "uses the Setup middleware first" do
          builder.uses[0].first.should == Aker::Rack::Setup
        end

        it "prepends middleware for UI modes after the Setup middleware" do
          builder.uses[1].first.should == :ui_ware_before
        end

        it "prepends middleware for API modes after UI modes" do
          builder.uses[2].first.should == :api_ware_before
        end

        it 'attaches the global before middleware immediately before warden' do
          @indexes[:global_before].should == @indexes[Warden::Manager] - 1
        end

        it 'attaches the global after middleware immediately after Aker::Rack::Authenticate' do
          @indexes[:global_after].should == @indexes[Aker::Rack::Authenticate] + 1
        end

        it "attaches the logout middleware after the global after middleware" do
          @indexes[Aker::Rack::Logout].should == @indexes[:global_after] + 1
        end

        it "attaches the session timer middleware after the logout middleware" do
          @session_timer_index.should == @logout_index + 1
        end

        it "attaches the default logout responder at the end of the chain" do
          builder.uses.map { |u| u.first }.last.should == Aker::Rack::DefaultLogoutResponder
        end

        it "mounts the logout middleware to /logout" do
          _, args, _ = builder.uses[@logout_index]

          args.should == ["/logout"]
        end

        it "appends middleware for UI modes directly after the session timer middleware" do
          @indexes[:ui_ware_after].should == @indexes[Aker::Rack::SessionTimer] + 1
        end

        it "appends middleware for API modes after appended UI middleware" do
          @indexes[:api_ware_after].should == @indexes[:ui_ware_after] + 1
        end

        it "uses middleware for the global configuration if no specific configuration is provided" do
          Aker.configure {
            ui_mode :ui_mode
          }

          builder = Aker::Spec::MockBuilder.new
          Aker::Rack.use_in(builder)

          builder.uses[0].first.should == Aker::Rack::Setup
          builder.uses[1].first.should == :ui_ware_before
          builder.uses[2].first.should_not == :api_ware_before
        end
      end

      it "attaches the aker middleware" do
        builder.should be_using(Aker::Rack::Setup, configuration)
      end

      it "passes on the configuration to the setup middleware if provided" do
        b = Aker::Spec::MockBuilder.new
        config = Aker::Configuration.new { portal :hello }

        Aker::Rack.use_in(b, config)

        b.should be_using(Aker::Rack::Setup, config)
      end
    end
  end

  describe Rack::Slice do
    let(:configuration) { Configuration.new(:slices => [Rack::Slice.new]) }

    describe 'parameter defaults' do
      describe 'for :policy' do
        subject { configuration.parameters_for(:policy) }

        it 'has [:session-timeout-seconds]' do
          subject[:'session-timeout-seconds'].should == 1800
        end
      end
    end
  end
end
