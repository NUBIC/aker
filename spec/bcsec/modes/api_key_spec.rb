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
      it "returns false if there does not exist a WWW-Authenticate header of the form 'ApiKey CHALLENGE'" do
        @mode.should_not be_valid
      end

      it "returns true if there exists a WWW-Authenticate header of the form 'ApiKey CHALLENGE'" do
        @env["HTTP_WWW_AUTHENTICATE"] = "ApiKey foo"

        @mode.should be_valid
      end
    end

    describe "#challenge" do
      it "returns ApiKey" do
        @mode.challenge.should == "ApiKey"
      end
    end
  end
end
