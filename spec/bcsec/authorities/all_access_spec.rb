require File.expand_path("../../../spec_helper", __FILE__)

module Bcsec::Authorities
  describe AllAccess do
    it "allows anyone and everything" do
      AllAccess.new(nil).may_access?("anyone", :anywhere).should be_true
    end
  end
end
