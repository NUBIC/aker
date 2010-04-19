require File.expand_path('../../../spec_helper', __FILE__)

module Bcsec::Authorities
  describe Cas do
    before do
      @config = Bcsec::Configuration.new do
        cas_parameters :base_url => "https://cas.example.net/cas"
      end
    end

    describe "initialization" do
      it "accepts a configuration" do
        Cas.new(@config)
      end

      it "requires a base URL in the configuration" do
        @config.parameters_for(:cas)[:base_url] = nil
        lambda { Cas.new(@config) }.should raise_error(":base_url parameter is required for CAS")
      end

      it "creates a cas client instance" do
        Cas.new(@config).client.class.should == CASClient::Client
        Cas.new(@config).client.cas_base_url.should == "https://cas.example.net/cas"
      end
    end

    describe "#valid_credentials?" do
      before do
        @authority = Cas.new(@config)
        @client = mock
        @authority.client = @client
      end

      it "doesn't support username-password" do
        @authority.valid_credentials?(:user, "a", "b").should == :unsupported
      end

      describe ":cas" do
        before do
          @ticket = "ST-bazola"
          @service = "https://example.org/app"
          @st = CASClient::ServiceTicket.new(@ticket, @service)
          @client.should_receive(:validate_service_ticket).and_return(@st)
        end

        it "returns a user based on the service ticket response" do
          @st.response = Class.new do
            def user; "jo"; end
            def is_failure?; false; end
          end.new

          @authority.valid_credentials?(:cas, @ticket, @service).username.should == "jo"
        end

        it "returns nil if the service ticket is invalid" do
          @st.response = Class.new do
            def is_failure?; true; end
          end.new

          @authority.valid_credentials?(:cas, @ticket, @service).should be_nil
        end

        it "requests and stores the pgt somehow"
      end

      describe ":cas_proxy" do
        it "returns a user based on the proxy ticket response"
        it "returns nil if the service ticket is invalid"
      end
    end
  end
end
