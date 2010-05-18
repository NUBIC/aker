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
end
