require File.expand_path("../../../spec_helper", __FILE__)

module Bcsec::Modes
  describe Cas do
    before do
      @env = {}
      @scope = mock
      @mode = Cas.new(@env, @scope)
    end

    describe "#key" do
      it "is :cas" do
        Cas.key.should == :cas
      end
    end

    describe "#valid?" do
      it "returns false if a service ticket is not in the query string"

      it "returns true if a service ticket is in the query string"
    end

    describe "#authenticate!" do
      it "signals success if the service ticket is good"

      it "does not signal success if the service ticket is bad"
    end

    describe "#on_ui_failure" do
      it "redirects to the CAS server's login page"

      it "uses the URL the user was trying to reach as the CAS service URL"
    end
  end
end
