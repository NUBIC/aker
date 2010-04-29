require File.expand_path("../../../spec_helper", __FILE__)
require File.expand_path("a_bcsec_mode", File.dirname(__FILE__))
require 'rack'

module Bcsec::Modes
  describe CasProxy do
    before do
      @env = Rack::MockRequest.env_for('/')
      @scope = mock
      @mode = CasProxy.new(@env, @scope)
      @env['bcsec.configuration'] = Bcsec::Configuration.new
    end

    it_should_behave_like "a bcsec mode"

    describe "#key" do
      it "is :cas_proxy" do
        CasProxy.key.should == :cas_proxy
      end
    end

    describe "#kind" do
      it "is :cas_proxy" do
        @mode.kind.should == :cas_proxy
      end
    end

    describe "#credentials" do
      it "finds a proxy ticket that starts with PT" do
        @env["HTTP_AUTHORIZATION"] = "CasProxy PT-1foo"

        @mode.credentials.should == ["PT-1foo"]
      end

      it "finds a proxy ticket that starts with ST" do
        @env["HTTP_AUTHORIZATION"] = "CasProxy ST-9936-bam"

        @mode.credentials.should == ["ST-9936-bam"]
      end

      it "ignores an out-of-spec proxy ticket" do
        @env["HTTP_AUTHORIZATION"] = "CasProxy MyAttackVector"

        @mode.credentials.should == []
      end

      it "returns an empty array if no proxy ticket is present" do
        @mode.credentials.should == []
      end
    end

    describe "#valid?" do
      it "returns false if there is no authorization header" do
        @mode.should_not be_valid
      end

      it "returns false if the authorization header is for a different scheme" do
        @env["HTTP_AUTHORIZATION"] = "Basic " + Base64.encode64("bas:baz")

        @mode.should_not be_valid
      end

      it "returns true if the authorization header is for CasProxy" do
        @env["HTTP_AUTHORIZATION"] = "CasProxy PT-5-256a"

        @mode.should be_valid
      end
    end

    describe "#scheme" do
      it "returns CasProxy" do
        @mode.scheme.should == "CasProxy"
      end
    end

    describe "#challenge" do
      it "includes the scheme and the realm" do
        @mode.challenge.should == "CasProxy realm=\"Bcsec\""
      end
    end

    describe "#authenticate!" do
      before do
        @authority = mock
        @mode.stub!(:authority => @authority)
        @env["HTTP_AUTHORIZATION"] = "CasProxy PT-1foo"
      end

      it "signals success if the proxy ticket is good" do
        user = stub
        @authority.should_receive(:valid_credentials?).with(:cas_proxy, "PT-1foo").and_return(user)
        @mode.should_receive(:success!).with(user)

        @mode.authenticate!
      end

      it "does not signal success if the proxy ticket is bad" do
        @authority.stub!(:valid_credentials? => nil)
        @mode.should_not_receive(:success!)

        @mode.authenticate!
      end
    end
  end
end
