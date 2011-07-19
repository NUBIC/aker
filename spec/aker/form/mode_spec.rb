require File.expand_path("../../../spec_helper", __FILE__)
require File.expand_path("../a_form_mode", __FILE__)
require "rack"

module Aker::Form
  describe Mode do
    it_should_behave_like "a form mode"

    describe "#key" do
      it "is :form" do
        Mode.key.should == :form
      end
    end
  end
end
