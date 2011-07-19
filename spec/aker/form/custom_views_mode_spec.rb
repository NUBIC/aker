require File.expand_path("../../../spec_helper", __FILE__)
require File.expand_path("../a_form_mode", __FILE__)
require "rack"

module Aker::Form
  describe CustomViewsMode do
    it_should_behave_like "a form mode"

    describe "#key" do
      it "is :custom_form" do
        CustomViewsMode.key.should == :custom_form
      end
    end

    describe "middleware" do
      let(:builder) { Aker::Spec::MockBuilder.new }

      it "prepends nothing" do
        CustomViewsMode.prepend_middleware(builder)
        builder.uses.should be_empty
      end

      it 'appends only one piece of middleware' do
        CustomViewsMode.append_middleware(builder)
        builder.should have(1).uses
      end

      it "appends its own login responder" do
        CustomViewsMode.append_middleware(builder)
        builder.should be_using(Middleware::CustomViewLoginResponder)
      end
    end
  end
end
