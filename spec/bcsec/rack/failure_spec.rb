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

    def call
      @app.call(@env)
    end

    def actual_code
      call[0]
    end

    def actual_headers
      call[1]
    end

    def actual_body
      actual_lines = []
      call[2].each { |l| actual_lines << l }
      actual_lines.join
    end

    describe "of authorization" do
      before do
        @env['bcsec'] = Facade.new(@env["bcsec.configuration"], Bcsec::User.new("jo"))
      end

      shared_examples_for "an authorization failure" do
        it "403s" do
          actual_code.should == 403
        end

        it "returns HTML" do
          actual_headers["Content-Type"].should == "text/html"
        end

        it "returns a somewhat friendly message" do
          actual_body.should ==
            "<html><head><title>Authorization denied</title></head><body>jo may not use this page.</body></html>"
        end
      end

      describe "at the portal level" do
        before do
          @env['warden.options'] = { :portal_required => :ENU }
        end

        it_should_behave_like "an authorization failure"

        it "logs the failure appropriately" do
          pending "#2702"
        end
      end

      describe "at the group level" do
        before do
          @env['warden.options'] = { :groups_required => [:Admin, :Developer] }
        end

        it_should_behave_like "an authorization failure"

        it "logs the failure appropriately" do
          pending "#2702"
        end
      end
    end

    describe "of authentication" do
      before do
        @env['warden.options'] = { :login_required => true }
      end

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
          actual_code.should == 403
          actual_body.should == "UI failed!"
        end
      end

      describe "when not interactive" do
        before do
          @env['bcsec.interactive'] = false

          %w(Alpha Beta).each do |n|
            cls = Class.new(Bcsec::Modes::Base)
            cls.class_eval(<<-RUBY)
              include Bcsec::Modes::Rfc2617
              def authenticate!; nil; end
              def scheme; #{n.inspect}; end
            RUBY
            Warden::Strategies.add(n.downcase.to_sym, cls)
          end
        end

        it "responds with a challenge" do
          @env['bcsec.configuration'].api_mode = :beta

          actual = call
          actual[0].should == 401
          actual[1]["WWW-Authenticate"].should == 'Beta realm="Bcsec"'
        end

        it "responds for with challenges for all modes" do
          @env['bcsec.configuration'].api_mode = [:beta, :alpha]

          actual_headers["WWW-Authenticate"].should == %Q{Beta realm="Bcsec"\nAlpha realm="Bcsec"}
        end

        it "uses the portal as the realm if it is set" do
          @env['bcsec.configuration'].portal = :ENU
          @env['bcsec.configuration'].api_mode = [:alpha]

          actual_headers["WWW-Authenticate"].should == %Q{Alpha realm="ENU"}
        end

        it "gives a human-readable message in the body for debugging" do
          @env['bcsec.configuration'].api_mode = :beta
          actual_headers["Content-Type"].should == "text/plain"
          actual_body.should == "Authentication required"
        end
      end
    end
  end
end
