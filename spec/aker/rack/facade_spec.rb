require File.expand_path('../../../spec_helper', __FILE__)

module Aker::Rack
  describe Facade do
    ##
    # @return [Object] the options passed to the warden throw
    # @raise RuntimeError if :warden is never thrown
    def catch_warden_throw(&block)
      opts = catch(:warden) do
        block.call
      end
      if opts
        opts
      else
        fail ":warden not thrown (or thrown without options)"
      end
    end

    before do
      @user = Aker::User.new("jo")
      @user.portals << :ENU
      @user.default_portal = :ENU
      @user.group_memberships << Aker::GroupMembership.new(Aker::Group.new("User"))

      @config = Aker::Configuration.new {
        portal :ENU
      }

      @with_user = Facade.new(@config, @user)
      @without_user = Facade.new(@config, nil)
    end

    describe "#authentication_required!" do
      it "throws to warden if there's no user" do
        catch_warden_throw {
          @without_user.authentication_required!
        }.should == { :login_required => true }
      end

      describe "with a user" do
        it "does not throw to warden if the user is authenticated and in the proper portal" do
          lambda { @with_user.authentication_required! }.should_not raise_error
        end

        it "throws to warden if the user isn't permitted to access the configured portal" do
          @config.portal = :NOTIS
          catch_warden_throw {
            @with_user.authentication_required!
          }.should == { :portal_required => :NOTIS }
        end

        it "does not throw to warden if there's no configured portal" do
          @config.portal = nil
          lambda { @with_user.authentication_required! }.should_not raise_error
        end
      end
    end

    describe "#authenticated?" do
      it "returns false if there's not a user" do
        @without_user.should_not be_authenticated
      end

      describe "with a user" do
        it "returns true if the user is in the configured portal" do
          @with_user.should be_authenticated
        end

        it "returns false if the user is not in the configured portal" do
          @config.portal = :NOTIS
          @with_user.should_not be_authenticated
        end

        it "returns true if there is no configured portal" do
          @config.portal = nil
          @with_user.should be_authenticated
        end
      end
    end

    describe "#permit?" do
      describe "without a block" do
        it "returns true if the facade user is in the group" do
          @with_user.permit?(:User).should be_true
        end

        it "returns false if the user is not in the group" do
          @with_user.permit?(:Admin).should be_false
        end

        it "returns false without a user" do
          @without_user.permit?(:User).should be_false
        end
      end

      describe "with a block" do
        it "evaluates the block if the facade user is in the group" do
          executed = false
          @with_user.permit?(:User) do
            executed = true
          end

          executed.should be_true
        end

        it "does not evaluate the block if the facade user is not in the group" do
          executed = false
          @with_user.permit?(:Admin) do
            executed = true
          end

          executed.should be_false
        end

        it "does not evaluate the block if there is no user" do
          executed = false
          @without_user.permit?(:User) do
            executed = true
          end

          executed.should be_false
        end
      end

      it "is aliased as permit (without the question mark)" do
        @with_user.permit(:User).should be_true
      end
    end

    describe "#permit!" do
      it "tells warden authentication is required if there's no user" do
        catch_warden_throw {
          @without_user.permit!(:User)
        }.should == { :login_required => true }
      end

      it "tells warden that particular groups are required if the user isn't in any of them" do
        catch_warden_throw {
          @with_user.permit!(:Developer, :Admin)
        }.should == { :groups_required => [:Developer, :Admin] }
      end
    end

    describe "#user" do
      it "returns the user if there's a user" do
        @with_user.user.username.should == "jo"
      end

      it "returns nil if there's no user" do
        @without_user.user.should be_nil
      end
    end
  end
end
