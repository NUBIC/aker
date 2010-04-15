require File.expand_path("../../../spec_helper", __FILE__)
require File.expand_path("a_bcsec_mode", File.dirname(__FILE__))
require 'rack'

module Bcsec::Modes
  describe CasProxy do
    before do
      @env = Rack::MockRequest.env_for('/')
      @scope = mock
      @mode = CasProxy.new(@env, @scope)
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
      it "returns the proxy ticket" do
        @env["QUERY_STRING"] = "PT=PT-1foo"

        @mode.credentials.should == ["PT-1foo"]
      end

      it "returns an empty array if no proxy ticket is present" do
        @mode.credentials.should == []
      end
    end

    describe "#valid?" do
      it "returns false if the PT parameter is not in the query string" do
        @mode.should_not be_valid
      end

      it "returns true if the PT parameter is in the query string" do
        @env["QUERY_STRING"] = "PT=PT-1foo"

        @mode.should be_valid
      end
    end

    describe "#scheme" do
      it "returns CasProxy" do
        @mode.scheme.should == "CasProxy"
      end
    end

    describe "#authenticate!" do
      before do
        @authority = mock
        @mode.stub!(:authority => @authority)
        @env["QUERY_STRING"] = "PT=PT-1foo"
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
