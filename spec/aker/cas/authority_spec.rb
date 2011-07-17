require File.expand_path('../../../spec_helper', __FILE__)

module Aker::Cas
  describe Authority do
    let(:config) do
      Aker::Configuration.new do
        cas_parameters :base_url => "https://cas.example.net/cas/"
      end
    end

    let(:authority) { Authority.new(config) }

    describe "initialization" do
      it "accepts a configuration" do
        Authority.new(config)
      end

      it "requires a base URL in the configuration" do
        config.parameters_for(:cas)[:base_url] = nil
        lambda { authority }.should raise_error(":base_url parameter is required for CAS")
      end

      describe "of the client" do
        it "has the right base URL" do
          authority.cas_url.should == "https://cas.example.net/cas/"
        end
      end
    end

    shared_examples_for "a CAS user modifier" do
      describe "user modification" do
        it "initializes the user with its proxy-granting ticket" do
          ticket.stub!(:pgt_iou => "PGTIOU-1foo", :pgt => "PGT-1foo")

          user = authority.valid_credentials?(kind, ticket, service)

          user.pgt.should == "PGT-1foo"
        end

        it "does not initialize the user with a proxy-granting ticket when a PGT IOU is absent" do
          ticket.stub!(:pgt_iou => nil)

          user = authority.valid_credentials?(kind, ticket, service)

          user.pgt.should be_nil
        end
      end
    end

    describe "#valid_credentials?" do
      it "doesn't support username-password" do
        authority.valid_credentials?(:user, "a", "b").should == :unsupported
      end

      describe ":cas" do
        let(:kind) { :cas }
        let(:service) { "https://example.org/app" }
        let(:st) { "ST-bazola" }
        let(:ticket) { stub.as_null_object }

        before do
          authority.stub!(:service_ticket => ticket)
        end

        it "returns a user based on the service ticket response" do
          ticket.stub!(:ok? => true, :username => "jo")

          authority.valid_credentials?(:cas, st, service).username.should == "jo"
        end

        it "returns nil if the service ticket is invalid" do
          ticket.stub!(:ok? => false)

          authority.valid_credentials?(:cas, st, service).should be_nil
        end

        it_should_behave_like "a CAS user modifier"
      end

      describe ":cas_proxy" do
        let(:kind) { :cas_proxy }
        let(:pt) { "PT-12thththhtthhhthhttp" }
        let(:service) { "https://example.org/app" }
        let(:ticket) { stub.as_null_object }

        before do
          authority.stub!(:proxy_ticket => ticket)
        end

        it "returns a user based on the proxy ticket response" do
          ticket.stub!(:ok? => true, :username => "jo")

          authority.valid_credentials?(:cas_proxy, pt, service).username.should == "jo"
        end

        it "returns nil if the proxy ticket is invalid" do
          ticket.stub!(:ok? => false)

          authority.valid_credentials?(:cas_proxy, pt, service).should be_nil
        end

        it_should_behave_like "a CAS user modifier"
      end
    end
  end
end
