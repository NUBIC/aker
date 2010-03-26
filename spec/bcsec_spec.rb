require File.expand_path('../spec_helper', __FILE__)

require 'bcsec'

describe Bcsec do
  describe "::VERSION" do
    it "exists" do
      lambda { Bcsec::VERSION }.should_not raise_error
    end

    it "has three or four dot-separated parts" do
      Bcsec::VERSION.split('.').size.should be_between(3, 4)
    end
  end
end
