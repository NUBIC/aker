require File.expand_path('../../spec_helper', __FILE__)

module Bcsec
  describe User do
    before do
      @u = User.new("jo", :airport)
      @u.first_name = "Jocelyn"
      @u.last_name = "Jordan"
    end

    describe "#full_name" do
      it "works with both names" do
        @u.full_name.should == "Jocelyn Jordan"
      end

      it "uses the user name with no names" do
        @u.first_name = nil
        @u.last_name = nil
        @u.full_name.should == "jo"
      end

      it "works with just the last name" do
        @u.first_name = nil
        @u.full_name.should == "Jordan"
      end

      it "works with just the first name" do
        @u.last_name = nil
        @u.full_name.should == "Jocelyn"
      end
    end

    describe "#may_access?" do
      it "permits access to a known portal" do
        @u.may_access?(:airport).should be_true
      end

      it "supports string-named portals" do
        @u.may_access?("airport").should be_true
      end

      it "refuses access to an unknown portal" do
        @u.may_access?(:seaport).should be_false
      end

      it "delegates to the authority for an unknown portal" do
        pending "redesign"
      end

      it "caches portal access information from the authority" do
        pending "redesign"
      end
    end

    describe "#in_group?" do
      it "works with no groups" do
        pending "redesign"
        User.new("fred").in_group?("any").should be_false
      end

      it "works for flat group sets"

      it "returns true if the user is member of at least one of an array of groups"

      describe "with hierarchies" do
        it "works for a group the user is an immediate member of"
        it "works for a group the user inherits membership of"
      end
    end

    describe "#actual_group" do
      it "works for immediate memberships"
      it "works for parent memberships"
      it "gives nil for child memberships"
    end

    describe "affiliate-constrained groups" do
      it "includes all affiliates for a nil-affiliated group membership"
      it "includes immediate affiliates"
      it "includes child affiliates"
      it "does not include parent affiliates"
    end
  end
end
