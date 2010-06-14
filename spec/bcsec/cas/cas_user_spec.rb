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
                            :pgt => "PGT-1foo"
                            )
      end

      it "allows you to request proxy tickets" do
        @client.should_receive(:request_proxy_ticket).once.
          with("PGT-1foo", "https://example.org/service-a").
          and_return(CASClient::ProxyTicket.new("PT-ABC", "https://example.org/service-a"))
        @client.should_receive(:request_proxy_ticket).once.
          with("PGT-1foo", "https://example.org/service-b").
          and_return(CASClient::ProxyTicket.new("PT-BCA", "https://example.org/service-b"))

        @user.cas_proxy_ticket("https://example.org/service-a").should == "PT-ABC"
        @user.cas_proxy_ticket("https://example.org/service-b").should == "PT-BCA"
      end
    end
  end
end
