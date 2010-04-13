require File.expand_path("../../../spec_helper", __FILE__)

module Bcsec::Modes
  describe ApiKey do
    before do
      @env = {}
      @scope = mock
      @mode = ApiKey.new(@env, @scope)
    end

    describe "#key" do
      it "is :api_key" do
        ApiKey.key.should == :api_key
      end
    end

    describe "#valid?" do
      it "returns false if there does not exist an Authorization header of the form 'ApiKey CHALLENGE'" do
        @mode.should_not be_valid
      end

      it "returns true if there exists an Authorization header of the form 'ApiKey CHALLENGE'" do
        @env["HTTP_AUTHORIZATION"] = "ApiKey foo"

        @mode.should be_valid
      end
    end

    describe "#scheme" do
      it "returns ApiKey" do
        @mode.scheme.should == "ApiKey"
      end
    end

    describe "#authenticate!" do
      before do
        @authority = mock
        @mode.stub!(:authority => @authority)
        @env["HTTP_AUTHORIZATION"] = "ApiKey foo"
      end

      it "signals success if the supplied API key is good" do
        user = stub
        @authority.should_receive(:valid_credentials?).with(:api_key, "foo").and_return(user)
        @mode.should_receive(:success!).with(user)

        @mode.authenticate!
      end

      it "returns nil if the supplied API key is bad" do
        @authority.should_receive(:valid_credentials?).with(:api_key, "foo").and_return(nil)
        @mode.should_not_receive(:success!)

        @mode.authenticate!
      end
    end
  end
end
