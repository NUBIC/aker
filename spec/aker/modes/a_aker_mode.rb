require File.expand_path("../../../spec_helper", __FILE__)
require 'warden'

##
# Expects the following instance variables to be set:
#
# * @mode: an instance of the mode under test
# * @env: a Rack environment used by the mode
shared_examples_for "a aker mode" do
  it "is a Warden strategy" do
    (@mode.class < Warden::Strategies::Base).should be_true
  end

  describe '#interactive?' do
    it "is true if 'aker.interactive' is true" do
      @env['aker.interactive'] = true

      @mode.interactive?.should == true
    end

    it "is false if 'aker.interactive' is false" do
      @env['aker.interactive'] = false

      @mode.interactive?.should == false
    end
  end

  describe '#store?' do
    it 'is true if #interactive? is true' do
      @mode.stub!(:interactive? => true)

      @mode.store?.should == true
    end

    it 'is false if #interactive? is false' do
      @mode.stub!(:interactive? => false)

      @mode.store?.should == false
    end
  end
end
