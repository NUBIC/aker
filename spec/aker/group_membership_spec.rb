require File.expand_path('../../spec_helper', __FILE__)

module Aker
  module GroupMembershipHelpers
    def group(root, children=[], grandchildren=[])
      req = Group.new(root)
      children.each { |n| req << Group.new(n) }
      if req.children.first
        grandchildren.each { |n| req.children.first << Group.new(n) }
      end
      req
    end

    def unaffiliated(g)
      GroupMembership.new(Group === g ? g : group(g))
    end

    def affiliated(g, *affiliate_ids)
      unaffiliated(g).tap { |gm| gm.affiliate_ids = affiliate_ids }
    end
  end

  describe GroupMemberships do
    include GroupMembershipHelpers

    it "exposes the related portal" do
      GroupMemberships.new(:ENU).portal.should == :ENU
    end

    it "is enumerable" do
      GroupMemberships.new(:NOTIS).should respond_to(:each)
      GroupMemberships.new(:NOTIS).should respond_to(:detect)
    end

    it "is appendable" do
      @gm = GroupMemberships.new(:NOTIS)
      @gm << GroupMembership.new(Group.new('User'))
      @gm.size.should == 1
    end

    def a_notis_user
      GroupMemberships.new(:NOTIS).tap do |gm|
        admin = group('Admin', %w(Manager Auditor), %w(User Observer))
        manager, auditor = admin.children
        user = manager.children.first
        gm << unaffiliated(auditor) << affiliated(user, 42) << affiliated(manager, 28)
      end
    end

    describe "#include?" do
      before do
        @gm = a_notis_user
      end

      describe "with an affiliate" do
        it "includes unaffiliated groups" do
          @gm.include?("Auditor", 28).should be_true
        end

        it "includes groups with a matching affiliate" do
          @gm.include?("User", 42).should be_true
        end

        it "excludes groups without a matching affiliate" do
          @gm.include?("Manager", 42).should be_false
        end

        it "excludes groups without a membership" do
          @gm.include?("Admin", 42).should be_false
        end

        it "includes transitive (child) groups" do
          @gm.include?("Observer", 28).should be_true
        end

        it "includes indirect affiliations for groups that also have a direct membership" do
          @gm.include?("User", 28).should be_true
        end

        it "includes any a group membership as long as one affiliate matches" do
          @gm.include?("Manager", 28, 42).should be_true
        end
      end

      describe "without an affiliate" do
        it "includes unaffiliated memberships" do
          @gm.include?("Auditor").should be_true
        end

        it "includes affiliated memberships" do
          @gm.include?("User").should be_true
        end

        it "excludes groups without a membership" do
          @gm.include?("Admin").should be_false
        end

        it "includes transitive (child) groups" do
          @gm.include?("Observer").should be_true
        end
      end

      it "is case-insensitive" do
        @gm.include?("auditoR").should be_true
      end
    end

    describe "find" do
      it "returns all matches" do
        actual = a_notis_user.find("User")
        actual.size.should == 2
        abstract = actual.collect { |gm| [gm.group_name, gm.affiliate_ids] }.sort_by { |p| p[0] }
        abstract[0].should == ["Manager", [28]]
        abstract[1].should == ["User", [42]]
      end

      it "returns specific affiliate matches" do
        actual = a_notis_user.find("Manager", 28, 42)
        actual.size.should == 1
        actual[0].group_name.should == "Manager"
        actual[0].affiliate_ids.should == [28]
      end

      it "returns nothing for an unmatched affiliate" do
        a_notis_user.find("Manager", 42).should == []
      end

      it "returns nothing for an unmatched group" do
        a_notis_user.find("Admin").should == []
      end
    end

    describe "serialization" do
      before do
        @user = a_notis_user
      end

      def marshal_and_unmarshal
        serialized = Marshal.dump(@user)
        Marshal.load(serialized)
      end

      it "works" do
        lambda { marshal_and_unmarshal }.should_not raise_error
      end

      it "includes all memberships" do
        marshal_and_unmarshal.size.should == 3
      end

      it "preserves the group relationships" do
        # this is a membership that is indirectly included via the
        # manager, 28 membership
        marshal_and_unmarshal.include?("User", 28).should be_true
      end

      it "does not have relationships that did not exist in the original" do
        marshal_and_unmarshal.include?("Admin").should be_false
      end

      it "preserves the portal" do
        marshal_and_unmarshal.portal.should == :NOTIS
      end
    end
  end

  describe GroupMembership do
    include GroupMembershipHelpers

    it "exposes the group name" do
      unaffiliated("foo").group_name.should == "foo"
    end

    it "exposes the group" do
      unaffiliated("foo").group.class.should == Aker::Group
    end

    it "never has a nil affiliate list" do
      unaffiliated("foo").affiliate_ids.should == []
    end

    describe "#include_affiliate?" do
      describe "when not affiliate-specific" do
        it "is always true" do
          unaffiliated("all").include_affiliate?(42).should be_true
        end
      end

      describe "when affiliate-specific" do
        before do
          @gm = affiliated("dc", 34, 42, "abc")
        end

        it "is true when the affiliate is present" do
          @gm.include_affiliate?(42).should be_true
        end

        it "is false when the affiliate is not present" do
          @gm.include_affiliate?(43).should be_false
        end

        it "accepts string affiliate IDs" do
          @gm.include_affiliate?("abc").should be_true
        end
      end
    end
  end
end
