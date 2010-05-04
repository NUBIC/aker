require File.expand_path('../../../spec_helper', __FILE__)

module Bcsec::Cas
  describe CasUser do
    before do
      @user = Bcsec::User.new('jo')
      @user.extend(CasUser)
    end

    it "adds an init_cas_user method to the instance" do
      @user.should respond_to(:init_cas_user)
    end

    describe "#cas_proxy_ticket" do
      before do
        @client = mock
        @user.init_cas_user(
                            :client => @client,
                            :pgt_iou => "IOU 1 PGT"
                            )
      end

      it "allows you to request proxy tickets" do
        expected_pgt = CASClient::ProxyGrantingTicket.new("PGT-75", "IOU 1 PGT")
        @client.stub(:proxy_retrieval_url => "https://something")
        @client.should_receive(:retrieve_proxy_granting_ticket).once.with("IOU 1 PGT").
          and_return(expected_pgt)
        @client.should_receive(:request_proxy_ticket).once.
          with(expected_pgt, "https://example.org/service-a").
          and_return(CASClient::ProxyTicket.new("PT-ABC", "https://example.org/service-a"))
        @client.should_receive(:request_proxy_ticket).once.
          with(expected_pgt, "https://example.org/service-b").
          and_return(CASClient::ProxyTicket.new("PT-BCA", "https://example.org/service-b"))

        @user.cas_proxy_ticket("https://example.org/service-a").should == "PT-ABC"
        @user.cas_proxy_ticket("https://example.org/service-b").should == "PT-BCA"
      end

      it "can't retrieve proxy tickets unless the client has a proxy retrieval URL" do
        @client.stub(:proxy_retrieval_url => nil)

        lambda { @user.cas_proxy_ticket("https://example.org/service-ola") }.
          should raise_error(/Cannot retrieve a CAS proxy ticket without a proxy retrieval URL/)
      end
    end
  end
end
