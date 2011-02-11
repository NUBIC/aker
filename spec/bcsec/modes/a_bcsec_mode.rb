require File.expand_path("../../../spec_helper", __FILE__)
require 'warden'

##
# Expects the following instance variables to be set:
#
# * @mode: an instance of the mode under test
# * @env: a Rack environment used by the mode
shared_examples_for "a bcsec mode" do
  it "is a Warden strategy" do
    (@mode.class < Warden::Strategies::Base).should be_true
  end

  describe '#interactive?' do
    it "is true if 'bcsec.interactive' is true" do
      @env['bcsec.interactive'] = true

      @mode.interactive?.should == true
    end

    it "is false if 'bcsec.interactive' is false" do
      @env['bcsec.interactive'] = false

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
