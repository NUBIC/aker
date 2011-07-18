require File.expand_path("../../../spec_helper", __FILE__)
require "rack/test"

module Aker::Test
  describe Helpers do
    describe "#login_env" do
      before do
        Aker.configure do
          s = Aker::Authorities::Static.new

          s.valid_credentials!(:user, "jo", "50-50")
          authorities s
        end

        @test_case = Class.new do
          include Aker::Test::Helpers
        end.new
      end

      shared_examples_for "a login helper" do
        it "generates a Rack environment containing an authenticated user" do
          @env['aker'].user.should_not be_nil
          @env['aker'].user.username.should == 'jo'
        end
      end

      describe 'given a username' do
        before do
          @env = @test_case.login_env("jo")
        end

        it_should_behave_like "a login helper"
      end

      describe 'given a Aker::User object' do
        before do
          @env = @test_case.login_env(Aker::User.new("jo"))
        end

        it_should_behave_like "a login helper"
      end
    end
  end
end
