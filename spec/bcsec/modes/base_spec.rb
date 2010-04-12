require File.expand_path("../../../spec_helper", __FILE__)
require 'warden'

module Bcsec::Modes
  describe Base do
    it "is a Warden strategy" do
      (Base < Warden::Strategies::Base).should be_true
    end
  end
end
