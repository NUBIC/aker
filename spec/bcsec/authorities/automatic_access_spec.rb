require File.expand_path("../../../spec_helper", __FILE__)

module Bcsec::Authorities
  describe AutomaticAccess do
    describe "initialization" do
      it "fails if the configuration has no portal" do
        lambda { AutomaticAccess.new(Bcsec::Configuration.new) }.should raise_error(
          "AutomaticAccess is unnecessary if you don't have a portal configured.")
      end
    end

    describe "#amplify!" do
      before do
        @authority = AutomaticAccess.new(Bcsec::Configuration.new { portal :ENU })
        @user = Bcsec::User.new('jo')
      end

      it "adds the configured portal to the portal list" do
        @authority.amplify!(@user)
        @user.portals.should include(:ENU)
      end

      it "does not add the portal if it is already there" do
        @user.portals << :ENU
        @authority.amplify!(@user)
        @user.portals.size.should == 1
      end

      it "sets the default portal if it isn't already set" do
        @authority.amplify!(@user)
        @user.default_portal.should == :ENU
      end

      it "leaves an existing default portal alone" do
        @user.default_portal = :NOTIS
        @authority.amplify!(@user)
        @user.default_portal.should == :NOTIS
      end

      it "returns the user" do
        @authority.amplify!(@user).should === @user
      end

      it "grants the user access" do
        @user.may_access?(:ENU).should be_false
        @authority.amplify!(@user)
        @user.may_access?(:ENU).should be_true
        @user.may_access?.should be_true
      end
    end
  end
end
