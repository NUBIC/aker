require File.expand_path("../../../spec_helper", __FILE__)

require 'fileutils'

module Aker::Authorities
  describe Static do
    before do
      @s = Static.new
    end

    describe "initialization" do
      it "will accept an argument" do
        lambda { Static.new('ignored') }.should_not raise_error
      end

      it "does not require an argument" do
        lambda { Static.new }.should_not raise_error
      end
    end

    describe "setting and checking credentials" do
      describe ":user" do
        before do
          @s.valid_credentials!(:user, "jo", "50-50")
        end

        it "gives the user for a valid combination" do
          @s.valid_credentials?(:user, "jo", "50-50").username.should == "jo"
        end

        it "gives nil for the wrong password" do
          @s.valid_credentials?(:user, "jo", "40-60").should be_nil
        end

        it "gives nil for an unknown user" do
          @s.valid_credentials?(:user, "joe", "50-50").should be_nil
        end

        describe "with duplicate passwords" do
          before do
            @s.valid_credentials!(:user, "joe", "50-50")
          end

          it "authenticates the first user" do
            @s.valid_credentials?(:user, "jo", "50-50").username.should == "jo"
          end

          it "authenticates the second user" do
            @s.valid_credentials?(:user, "joe", "50-50").username.should == "joe"
          end
        end
      end

      describe "other kinds" do
        before do
          @s.valid_credentials!(:magic, "jo", "abracadabra")
        end

        it "gives the user for a valid key" do
          @s.valid_credentials?(:magic, "abracadabra").username.should == "jo"
        end

        it "gives nil for an unknown key" do
          @s.valid_credentials?(:magic, "shazam").should be_nil
        end

        it "gives nil for an unknown kind" do
          @s.valid_credentials?(:radar, "abracadabra").should be_nil
        end
      end
    end

    describe "setting up user data" do
      let(:user) do
        @s.valid_credentials?(:user, "jo", "abracadabra").tap { |u| @s.amplify!(u) }
      end

      before do
        @s.valid_credentials!(:user, "jo", "abracadabra") do |u|
          u.in_group!(:ENU, "User")
        end
      end

      it "grants the user access to the given portals" do
        user.may_access?(:ENU).should be_true
      end

      it "does not grant access to non-specified portals" do
        user.may_access?(:SQLSubmit).should be_false
      end

      it "assigns groups to users" do
        user.permit?("User", :portal => :ENU).should be_true
      end

      it "permits user attributes to be set" do
        @s.valid_credentials!(:user, "jo", "abracadabra") do |u|
          u.first_name = "Josephine"
        end

        user.first_name.should == "Josephine"
      end

      describe "with affiliates" do
        before do
          @s.valid_credentials!(:user, "jo", "abracadabra") do |u|
            u.in_group!(:NOTIS, "Manager", :affiliate_ids => [20])
          end
        end

        it "adds affiliate matches to groups" do
          user.group_memberships(:NOTIS).include?("Manager", 20).should be_true
          user.group_memberships(:NOTIS).include?("Manager", 21).should be_false
        end
      end

      it "coalesces group memberships" do
        @s.valid_credentials!(:user, "jo", "abracadabra") do |u|
          u.in_group!(:NOTIS, "Manager")
          u.in_group!(:NOTIS, "Manager", :affiliate_ids => [20])
        end

        user.group_memberships(:NOTIS).include?("Manager", 20).should be_true
      end
    end

    describe "accessing users" do
      it "reuses a user added with valid_credentials!" do
        @s.valid_credentials!(:user, "jo", "123")
        @s.user("jo").object_id.should == @s.valid_credentials?(:user, "jo", "123").object_id
      end

      it "creates a user on first reference" do
        @s.user("jo").username.should == "jo"
      end

      it "reuses user across multiple calls" do
        @s.user("jo").object_id.should == @s.user("jo").object_id
      end

      it "yields the user to a block, if given" do
        @s.user("jo") do |u|
          u.first_name = "Josephine"
        end

        @s.user("jo").first_name.should == "Josephine"
      end
    end

    describe "#amplify!" do
      before do
        @s.user("jo") do |u|
          u.first_name = "Josephine"
          u.last_name = "Mueller"
          u.portals += [:ENU, :NOTIS]
          u.group_memberships(:ENU) << Aker::GroupMembership.new(Aker::Group.new("User"))
        end

        @outside_jo = Aker::User.new("jo")
      end

      def actual
        @s.amplify!(@outside_jo)
      end

      it "does nothing for an unknown user" do
        lambda { @s.amplify!(Aker::User.new("joe")) }.should_not raise_error
      end

      describe "on a blank instance" do
        it "copies simple attributes" do
          actual.first_name.should == "Josephine"
        end

        it "copies portals" do
          actual.portals.should == [:ENU, :NOTIS]
        end

        it "copies group memberships" do
          actual.group_memberships(:ENU).size.should == 1
        end
      end

      describe "for portals" do
        before do
          @outside_jo.portals += [:ENU, :SQLSubmit]
        end

        it "only includes each portal once" do
          actual.portals.size.should == 3
        end

        it "retains portals that are in both lists" do
          actual.may_access?(:ENU).should be_true
        end

        it "adds portals from the static authority" do
          actual.may_access?(:NOTIS).should be_true
        end

        it "retains portals that are only in the pre-amplified user" do
          actual.may_access?(:SQLSubmit).should be_true
        end
      end

      describe "for group memberships" do
        it "copies group memberships for an otherwise unknown portal" do
          @outside_jo.group_memberships(:NOTIS) <<
            Aker::GroupMembership.new(Aker::Group.new("Admin"))

          actual.group_memberships(:ENU).size.should == 1
        end

        it "leaves alone group memberships for a known portal" do
          @outside_jo.group_memberships(:ENU) <<
            Aker::GroupMembership.new(Aker::Group.new("Developer"))

          actual.group_memberships(:ENU).include?("Developer").should be_true
          actual.group_memberships(:ENU).include?("User").should be_false
        end
      end
    end

    describe "#find_users" do
      before do
        @s.user('alpha') do |u|
          u.first_name = 'A'
          u.last_name = 'Pha'
          u.middle_name = 'L.'
        end

        @s.user('epsilon') do |u|
          u.first_name = 'Epsi'
          u.last_name = 'On'
          u.middle_name = 'L.'
        end
      end

      describe "with a username" do
        it "returns the sole matching user" do
          @s.find_users("alpha").collect(&:first_name).should == %w(A)
        end

        it "returns an empty list for no users" do
          @s.find_users("gamma").should == []
        end
      end

      describe "with a hash of criteria" do
        it "matches on user attributes" do
          @s.find_users(:middle_name => 'L.').size.should == 2
        end

        it "ignores unknown attributes" do
          @s.find_users(:username => 'epsilon', :frob => 'yelp').size.should == 1
        end

        it "returns nothing if the criteria contains no known attributes" do
          @s.find_users(:frob => 'hork').size.should == 0
        end

        it "combines attributes with AND" do
          @s.find_users(:first_name => 'A', :last_name => 'Pha').size.should == 1
          @s.find_users(:first_name => 'A', :last_name => 'On').size.should == 0
        end
      end

      describe "with a list" do
        describe "of usernames" do
          it "returns the correct users" do
            @s.find_users("epsilon", "gamma", "alpha").
              collect(&:first_name).sort.should == %w(A Epsi)
          end
        end

        describe "of criteria hashes" do
          it "returns all matching users" do
            @s.find_users({ :first_name => 'A' }, { :last_name => 'On' }).should have(2).users
          end

          it "does not include duplicates" do
            @s.find_users({ :first_name => 'A' }, { :last_name => 'Pha' }).should have(1).user
          end
        end

        describe "of both" do
          it "returns the correct matches" do
            @s.find_users({ :last_name => 'Pha' }, 'epsilon').collect(&:username).sort.
              should == %w(alpha epsilon)
          end
        end
      end
    end

    describe "#load!" do
      it "does not fail with an empty yaml doc" do
        lambda { @s.load!(StringIO.new("")) }.should_not raise_error
      end

      it "does not fail with just users" do
        lambda { @s.load!(StringIO.new("users: {}")) }.should_not raise_error
      end

      it "does not fail with just groups" do
        lambda { @s.load!(StringIO.new("groups: {}")) }.should_not raise_error
      end

      it "returns self" do
        @s.load!(StringIO.new).object_id.should == @s.object_id
      end

      describe "from YAML" do
        before do
          @s.load!(StringIO.new(<<-YAML))
          users:
            jo:
              password: qofhearts
              first_name: "Jo"
              middle_name: "Middle"
              last_name: "Last"
              title: "Queen"
              business_phone: "(706)634-5789"
              fax: "(706) 867-5309"
              email: "jo@test.com"
              address: "123 Fake St"
              city: "Chicago"
              state: "Illinois"
              country: "USA"
              identifiers:
                personnel_id: 1
                nu_employee_id: 2
              portals:
                - SQLSubmit
                - ENU:
                  - User
                  - Developer
                - NOTIS:
                  - Auditor
                  - Manager: [20, 30]
          groups:
            NOTIS:
              - Admin:
                - Manager:
                  - User:
                    - Viewer
                - Auditor
          YAML
        end

        it "associates the password" do
          @s.valid_credentials?(:user, "jo", "qofhearts").should be_true
        end

        describe "user attributes" do
          before do
            @jo = @s.user("jo")
          end

          describe "other user attributes" do
            it "includes personnel_id" do
              @jo.identifiers[:personnel_id].should == 1
            end

            it "includes first_name" do
              @jo.first_name.should == "Jo"
            end

            it "includes middle_name" do
              @jo.middle_name.should == "Middle"
            end

            it "includes last_name" do
              @jo.last_name.should == "Last"
            end

            it "includes title" do
              @jo.title.should == "Queen"
            end

            it "includes business_phone" do
              @jo.business_phone.should == "(706)634-5789"
            end

            it "includes fax" do
              @jo.fax.should == "(706) 867-5309"
            end

            it "includes email" do
              @jo.email.should == "jo@test.com"
            end

            it "includes address" do
              @jo.address.should == "123 Fake St"
            end

            it "includes city" do
              @jo.city.should == "Chicago"
            end

            it "includes state" do
              @jo.state.should == "Illinois"
            end

            it "includes country" do
              @jo.country.should == "USA"
            end

            it "includes nu_employee_id" do
              @jo.identifiers[:nu_employee_id].should == 2
            end
          end

          describe "portals" do
            it "includes groupless portals" do
              @jo.may_access?(:SQLSubmit).should be_true
            end

            it "includes portals with simple groups" do
              @jo.may_access?(:ENU).should be_true
            end

            it "includes portals with affiliate-based groups" do
              @jo.may_access?(:NOTIS).should be_true
            end

            it "does not include other portals" do
              @jo.may_access?(:foo).should be_false
            end
          end

          it "uses the first listed portal as the default" do
            @jo.default_portal.should == :SQLSubmit
          end

          describe "group memberships" do
            it "is empty for groupless portals" do
              @jo.group_memberships(:SQLSubmit).should == []
            end

            it "includes direct groups for flat-grouped portals" do
              @jo.group_memberships(:ENU).include?("User").should be_true
            end

            it "includes direct groups for hierarchically-grouped portals" do
              @jo.group_memberships(:NOTIS).include?("Auditor").should be_true
            end

            it "includes child groups for hierarchically-grouped portals" do
              @jo.group_memberships(:NOTIS).include?("User").should be_true
            end

            it "includes affiliate matches for affiliate-restricted groups" do
              @jo.group_memberships(:NOTIS).include?("Manager", 20).should be_true
              @jo.group_memberships(:NOTIS).include?("Manager", 21).should be_false
            end
          end
        end
      end
    end

    it "can be created from a file" do
      fn = '/tmp/aker.yml'
      File.open(fn, 'w') do |f|
        f.write <<-YAML
        users:
          jo:
            password: q
        YAML
      end
      new_one = Static.from_file(fn)
      FileUtils.rm fn

      new_one.valid_credentials?(:user, "jo", "q").should be_true
    end

    describe "#clear" do
      before do
        @s.load!(StringIO.new(<<-YAML))
        users:
          jo:
            password: foo
            portals:
              - SQLSubmit
        groups:
          NOTIS:
            - Admin
        YAML
        @s.clear
      end

      it "clears the users" do
        @s.user("jo").may_access?(:SQLSubmit).should be_false
      end

      it "clears the groups" do
        # groups aren't otherwise exposed
        @s.instance_eval { @groups }.size.should == 0
      end

      it "clears the credentials" do
        @s.valid_credentials?(:user, "jo", "foo").should be_nil
      end

      it "returns self" do
        @s.clear.object_id.should == @s.object_id
      end
    end
  end
end
