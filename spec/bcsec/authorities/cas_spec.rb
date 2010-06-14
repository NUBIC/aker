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

      describe "of the client" do
        before do
          @actual_client = Cas.new(@config).client
        end

        it "is a rubycas-client instance" do
          @actual_client.class.should == CASClient::Client
        end

        it "has the right base URL" do
          @actual_client.cas_base_url.should == "https://cas.example.net/cas"
        end
      end
    end

    shared_examples_for "a CAS user modifier" do
      describe "user modification" do
        before do
          @t.response = mock_validation_response(true, "jo", "PGTIOU-bazmotron")
          @authority.stub!(:retrieve_pgt => "PGT-1foo")

        end

        it "mixes in Bcsec::Cas::CasUser" do
          user = @authority.valid_credentials?(@kind, @ticket, @service)

          user.should respond_to(:init_cas_user)
        end

        it "initializes the user with its proxy-granting ticket" do
          user = @authority.valid_credentials?(@kind, @ticket, @service)

          user.send(:instance_variable_get, :@cas_pgt).should == "PGT-1foo"
        end

        it "does not initialize the user with a proxy-granting ticket when a PGT IOU is absent" do
          @t.response = mock_validation_response(true, "jo", nil)

          user = @authority.valid_credentials?(@kind, @ticket, @service)

          user.send(:instance_variable_get, :@cas_pgt).should be_nil
        end

        it "initializes the user with the client" do
          user = @authority.valid_credentials?(@kind, @ticket, @service)

          user.send(:instance_variable_get, :@cas_client).should == @client
        end
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

      def mock_validation_response(success, user="jo", pgt_iou="PGT-1")
        mock.tap do |response|
          response.stub!(:user => user)
          response.stub!(:is_success? => success)
          response.stub!(:is_failure? => !success)
          response.stub!(:pgt_iou => pgt_iou)
        end
      end

      describe ":cas" do
        before do
          @ticket = "ST-bazola"
          @service = "https://example.org/app"
          @t = CASClient::ServiceTicket.new(@ticket, @service)
          @client.should_receive(:validate_service_ticket).and_return(@t)
          @client.stub!(:proxy_retrieval_url => "https://something",
                        :retrieve_proxy_granting_ticket => "PGT-1foo")
          @kind = :cas # for shared examples
        end

        it "returns a user based on the service ticket response" do
          @t.response = mock_validation_response(true)

          @authority.valid_credentials?(:cas, @ticket, @service).username.should == "jo"
        end

        it "returns nil if the service ticket is invalid" do
          @t.response = mock_validation_response(false)

          @authority.valid_credentials?(:cas, @ticket, @service).should be_nil
        end

        it_should_behave_like "a CAS user modifier"
      end

      describe ":cas_proxy" do
        before do
          @ticket = "PT-12thththhtthhhthhttp"
          @service = "https://example.org/app"
          @t = CASClient::ProxyTicket.new(@ticket, @service)
          @client.should_receive(:validate_proxy_ticket).and_return(@t)
          @client.stub!(:proxy_retrieval_url => "https://something",
                        :retrieve_proxy_granting_ticket => "PGT-1foo")
          @kind = :cas_proxy
        end

        it "returns a user based on the proxy ticket response" do
          @t.response = mock_validation_response(true)

          @authority.valid_credentials?(:cas_proxy, @ticket, @service).username.should == "jo"
        end

        it "returns nil if the proxy ticket is invalid" do
          @t.response = mock_validation_response(false)

          @authority.valid_credentials?(:cas_proxy, @ticket, @service).should be_nil
        end

        it_should_behave_like "a CAS user modifier"
      end
    end

    describe "#retrieve_pgt" do
      before do
        @authority = Cas.new(@config)
        @client = mock
        @authority.client = @client
      end

      it "retrieves a proxy-granting ticket given a PGT IOU" do
        @client.stub!(:proxy_retrieval_url => "https://something")
        @client.should_receive(:retrieve_proxy_granting_ticket).with("PGTIOU-1foo").and_return("PGT-1foo")

        pgt = @authority.retrieve_pgt("PGTIOU-1foo")

        pgt.should == "PGT-1foo"
      end

      it "can't retrieve proxy tickets unless a proxy retrieval URL is set" do
        @client.stub!(:proxy_retrieval_url => nil)

        lambda { @authority.retrieve_pgt("PGTIOU-1foo") }.
          should raise_error(/Cannot retrieve a CAS proxy ticket without a proxy retrieval URL/)
      end
    end
  end
end
