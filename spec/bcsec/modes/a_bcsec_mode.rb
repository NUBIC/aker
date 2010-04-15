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

  describe "#parameters_for" do
    it "reads configuration data from env['bcsec.configuration']" do
      config = mock
      config.should_receive(:parameters_for).with(:foo).and_return({})
      @env['bcsec.configuration'] = config

      @mode.parameters_for(:foo).should == {}
    end
  end
end
