require File.expand_path('../../../spec_helper', __FILE__)

require 'rack/mock'

module Bcsec::Rack
  describe Failure do
    before do
      @env = ::Rack::MockRequest.env_for("/", "bcsec.configuration" => Bcsec::Configuration.new)
      @app = Failure.new
    end

    after do
      Warden::Strategies.clear!
    end

    describe "on authentication" do
      describe "when interactive" do
        before do
          Warden::Strategies.add(:fake_ui) do
            def authenticate!; nil; end
            def on_ui_failure
              ::Rack::Response.new(["UI failed!"], 403, {})
            end
          end

          @env['bcsec.interactive'] = true
          @env['bcsec.configuration'].ui_mode = :fake_ui
        end

        it "invokes #on_ui_failure on the appropriate mode" do
          actual_code, actual_headers, actual_body = @app.call(@env)
          actual_code.should == 403
          actual_lines = []
          actual_body.each do |l|
            actual_lines << l
          end
          actual_lines.should == ["UI failed!"]
        end
      end

      describe "when not interactive" do
        before do
          @env['bcsec.interactive'] = false

          %w(Alpha Beta).each do |n|
            cls = Class.new(Bcsec::Modes::Base)
            cls.class_eval <<-RUBY
              include Bcsec::Modes::Rfc2617
              def authenticate!; nil; end
              def scheme; #{n.inspect}; end
            RUBY
            Warden::Strategies.add(n.downcase.to_sym, cls)
          end
        end

        it "responds with a challenge" do
          @env['bcsec.configuration'].api_mode = :beta

          actual = @app.call(@env)
          actual[0].should == 401
          actual[1]["WWW-Authenticate"].should == 'Beta realm="Bcsec"'
        end

        it "responds for with challenges for all modes" do
          @env['bcsec.configuration'].api_mode = [:beta, :alpha]

          actual = @app.call(@env)
          actual[1]["WWW-Authenticate"].should == %Q{Beta realm="Bcsec"\nAlpha realm="Bcsec"}
        end

        it "uses the portal as the realm if it is set" do
          @env['bcsec.configuration'].portal = :ENU
          @env['bcsec.configuration'].api_mode = [:alpha]

          actual = @app.call(@env)
          actual[1]["WWW-Authenticate"].should == %Q{Alpha realm="ENU"}
        end
      end
    end
  end
end
