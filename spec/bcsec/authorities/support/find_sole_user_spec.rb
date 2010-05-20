require File.expand_path('../../../../spec_helper', __FILE__)

module Bcsec::Authorities::Support
  describe FindSoleUser do
    class UserFinder
      include Bcsec::Authorities::Support::FindSoleUser

      def initialize(expected_users)
        @expected_users = expected_users
      end

      def find_users(criteria)
        @expected_users
      end
    end

    describe "#find_user" do
      it "returns a single user if only one matches" do
        UserFinder.new([ Bcsec::User.new('jo') ]).
          find_user("jo").username.should == 'jo'
      end

      it "returns nil if more than one user matches" do
        UserFinder.new([ Bcsec::User.new('a'), Bcsec::User.new('b') ]).
          find_user(:letter => :single).should be_nil
      end

      it "returns nil if no users match" do
        UserFinder.new([]).find_user("jo").should be_nil
      end
    end
  end
end
