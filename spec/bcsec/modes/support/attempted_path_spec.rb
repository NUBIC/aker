require File.expand_path("../../../../spec_helper", __FILE__)

module Bcsec::Modes::Support
  describe AttemptedPath do
    before do
      @object = Object.new
      @object.extend(AttemptedPath)
      @env = {}
      @object.stub!(:env => @env)
    end

    describe "#attempted_path" do
      it "returns the value of :attempted_path in warden.options" do
        @env["warden.options"] = {
          :attempted_path => "http://www.example.edu"
        }

        @object.attempted_path.should == "http://www.example.edu"
      end

      it "returns nil if :attempted_path is nil" do
        @env["warden.options"] = {}

        @object.attempted_path.should be_nil
      end

      it "returns nil if warden.options is not in the Rack environment" do
        @object.attempted_path.should be_nil
      end
    end
  end
end
