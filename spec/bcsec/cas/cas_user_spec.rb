require File.expand_path('../../../spec_helper', __FILE__)

module Bcsec::Cas
  describe CasUser do
    let(:user) { Bcsec::User.new("jo") }

    before do
      user.extend(CasUser)
    end

    describe "#cas_proxy_ticket" do
      let(:pgt) { "PGT-1foo" }
      let(:service) { "https://example.org/service-a" }

      before do
        user.pgt = 'PGT-1foo'
      end

      it "allows you to request proxy tickets" do
        user.should_receive(:issue_proxy_ticket).with(pgt, service).once.and_return(stub(:ticket => "PT-ABC"))

        user.cas_proxy_ticket("https://example.org/service-a").should == "PT-ABC"
      end
    end
  end
end
