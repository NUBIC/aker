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

    describe "#default_portal" do
      it "is always a symbol" do
        u = User.new('jo')
        u.default_portal = 'foo'
        u.default_portal.should == :foo
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

      it "uses the default portal if available"
      it "fails without a portal if there's no default"

      it "delegates to the authority for an unknown portal" do
        pending "redesign"
      end

      it "caches portal access information from the authority" do
        pending "redesign"
      end
    end

    describe "#group_memberships" do
      it "is a Bcsec::GroupMemberships instance" do
        User.new('jo').group_memberships(:ENU).class.should == GroupMemberships
      end

      it "defaults to the groups for the default portal" do
        jo = User.new('jo')
        jo.default_portal = :ENU
        jo.group_memberships(:ENU) << GroupMembership.new(Group.new('Developer'))
        jo.group_memberships(:NOTIS) << GroupMembership.new(Group.new('Admin'))

        jo.group_memberships.include?('Developer').should be_true
        jo.group_memberships.include?('Admin').should be_false
      end

      it "locates a portal given as a string" do
        jo = User.new('jo')
        jo.group_memberships(:ENU) << GroupMembership.new(Group.new('Developer'))
        jo.group_memberships("ENU").size.should == 1
      end

      it "fails without the portal parameter if there's no default portal" do
        lambda { User.new('jo').group_memberships }.should raise_error(/No default portal/)
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
  end
end
