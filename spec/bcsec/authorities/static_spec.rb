require File.expand_path("../../../spec_helper", __FILE__)

require 'fileutils'

module Bcsec::Authorities
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
          u.group_memberships(:ENU) << Bcsec::GroupMembership.new(Bcsec::Group.new("User"))
        end

        @outside_jo = Bcsec::User.new("jo")
      end

      def actual
        @s.amplify!(@outside_jo)
      end

      it "does nothing for an unknown user" do
        lambda { @s.amplify!(Bcsec::User.new("joe")) }.should_not raise_error
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
            Bcsec::GroupMembership.new(Bcsec::Group.new("Admin"))

          actual.group_memberships(:ENU).size.should == 1
        end

        it "leaves alone group memberships for a known portal" do
          @outside_jo.group_memberships(:ENU) <<
            Bcsec::GroupMembership.new(Bcsec::Group.new("Developer"))

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
              personnel_id: 1
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
              nu_employee_id: 1
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
							@jo.personnel_id.should == 1
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
							@jo.nu_employee_id.should == 1
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
      fn = '/tmp/bcsec.yml'
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

    describe "treatment of deprecated methods from MockAuthenticator" do
      describe "#valid_credentials! without a kind" do
        before do
          @s.valid_credentials!("suzy", "q")
        end

        it "gets a warning" do
          deprecation_message.should =~ /Please specify a kind in valid_credentials!/
          deprecation_message.should =~ /2\.2/
        end

        it "assumes that the kind is :user" do
          @s.valid_credentials?(:user, "suzy", "q").should be_true
        end
      end

      describe "#may_access!" do
        before do
          @s.may_access!("suzy", :ENU)
        end

        it "gets a warning" do
          deprecation_message.should =~
            /may_access! is deprecated.  Directly add portals via #user or use #load!./
          deprecation_message.should =~ /2\.2/
        end

        it "is converted into a portal append" do
          @s.user("suzy").may_access?(:ENU).should be_true
        end
      end

      it "fails on in_group!" do
        @s.in_group!("suzy", "foo", "bar")
        deprecation_message.should =~
          /in_group! is deprecated.  Directly add groups for a particular portal via #user or use #load!./
        deprecation_message.should =~ /2\.0/
      end

      it "fails on load_credentials!" do
        @s.load_credentials!("dc")
        deprecation_message.should =~
          /load_credentials! is deprecated.  Convert your YAML to the format supported by #load! and use it instead./
        deprecation_message.should =~ /2\.0/
      end

      it "fails on #all_groups" do
        @s.all_groups
        deprecation_message.should =~ /all_groups is no longer part of the auth API./
        deprecation_message.should =~ /2\.0/
      end

      it "fails on #add_groups" do
        @s.add_groups
        deprecation_message.should =~
          /Since all_groups is no longer part of the auth API, you don't need to mock its contents with add_groups./
        deprecation_message.should =~ /2\.0/
      end

      it "fails on #add_group" do
        @s.add_group
        deprecation_message.should =~
          /Since all_groups is no longer part of the auth API, you don't need to mock its contents with add_groups./
        deprecation_message.should =~ /2\.0/
      end

      it "fails on #portals" do
        @s.portals
        deprecation_message.should =~ /The portal list is not directly exposed./
        deprecation_message.should =~ /2\.0/
      end

      it "fails on #users=" do
        @s.users = []
        deprecation_message.should =~
          /The user list is not directly settable.  Use #user or #load!./
        deprecation_message.should =~ /2\.0/
      end

      it "fails on #users" do
        @s.users
        deprecation_message.should =~
          /The user list is not directly readable.  Use #user to read one user at a time./
        deprecation_message.should =~ /2\.0/
      end

      it "fails on #group_memberships" do
        @s.group_memberships
        deprecation_message.should =~
          /group_memberships are not directly mutable.  Use #user for one or #load! for many./
        deprecation_message.should =~ /2\.0/
      end
    end
  end
end
