require File.expand_path("../../../spec_helper", __FILE__)
require 'rack'

module Bcsec::Modes
  describe HttpBasic do
    before do
      @env = Rack::MockRequest.env_for('/')
      @scope = mock
      @mode = HttpBasic.new(@env, @scope)
    end

    describe "#key" do
      it "is :http_basic" do
        HttpBasic.key.should == :http_basic
      end
    end

    describe "#valid?"

    describe "#scheme" do
      it "returns Basic with a realm" do
        @mode.realm = 'Realm'

        @mode.scheme.should == "Basic realm=Realm"
      end
    end

    describe "#authenticate!"

    describe "#on_ui_failure"
  end
end
