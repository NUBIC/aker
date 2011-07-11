require File.expand_path('../../spec_helper', __FILE__)

require 'bcsec/central_parameters'

module Bcsec
  describe CentralParameters do
    describe "creating from a YAML file" do
      before do
        @actual = CentralParameters.new(File.expand_path("../bcsec-sample.yml", __FILE__))
      end

      it "loads new keys" do
        @actual[:netid][:user].should == "cn=foo"
      end

      it "loads top-level keys that aren't in the default set" do
        @actual[:foo][:bar].should == 'baz'
      end
    end

    describe "creating from a hash" do
      before do
        @source = {
          :cc_pers => { :user => 'cc_pers_bar', :password => 'secret' },
          :foo => { :bar => 'baz' }
        }
        @actual = CentralParameters.new(@source)
      end

      it "loads new keys" do
        @actual[:cc_pers][:password].should == 'secret'
      end

      it "loads top-level keys that aren't in the default set" do
        @actual[:foo][:bar].should == 'baz'
      end

      it "does not reflect changes to the source hash" do
        @source[:cc_pers][:user] = 'cc_pers_etc'
        @actual[:cc_pers][:user].should == 'cc_pers_bar'
      end
    end
  end
end
