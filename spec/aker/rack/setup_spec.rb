require File.expand_path('../../../spec_helper', __FILE__)

module Aker::Rack
  describe Setup do
    let(:app) { lambda { |x| x } }
    let(:configuration) { Aker::Configuration.new }
    let(:middleware) { Setup.new(app, configuration) }

    def call(env = {})
      middleware.call(env)
    end

    describe "env['aker.configuration']" do
      it "is the configuration provided in its constructor" do
        env = call

        env['aker.configuration'].should == configuration
      end
    end

    describe "env['aker.authority']" do
      it "is the authority from the configuration" do
        authority = stub
        configuration.stub!(:composite_authority => authority)

        env = call

        env['aker.authority'].should == authority
      end
    end

    describe "env['aker.interactive']" do
      it "is true if the Accept header includes text/html" do
        env = call("HTTP_ACCEPT" =>
                   "application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5")

        env['aker.interactive'].should be_true
      end

      describe "when there are any API modes" do
        let(:configuration) do
          Aker::Configuration.new do
            api_mode :http_basic
          end
        end

        it "is false if the Accept header does not include text/html" do
          env = call("HTTP_ACCEPT" => "*/*")

          env['aker.interactive'].should be_false
        end

        it "is false if there is no Accept header" do
          env = call

          env['aker.interactive'].should be_false
        end

        it "is true if the User-Agent header contains 'Mozilla'" do
          env = call("HTTP_USER_AGENT" => "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1)")

          env['aker.interactive'].should be_true
        end
      end

      describe "when there are no API modes" do
        it "is true if the Accept header does not include text/html" do
          env = call("HTTP_ACCEPT" => "*/*")

          env['aker.interactive'].should be_true
        end

        it "is true if there is no Accept header" do
          env = call

          env['aker.interactive'].should be_true
        end
      end
    end

    it "always invokes the app" do
      app.should_receive(:call)

      middleware.call({})
    end
  end
end
