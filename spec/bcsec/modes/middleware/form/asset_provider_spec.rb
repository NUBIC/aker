require File.expand_path("../../../../../spec_helper", __FILE__)
require 'nokogiri'

module Bcsec::Modes::Middleware::Form
  describe AssetProvider do
    before do
      @provider = AssetProvider.new
    end

    describe "#login_html" do
      before do
        env = { 'SCRIPT_NAME' => '/foo' }
        @doc = Nokogiri.HTML(@provider.login_html(env))
      end

      it "includes SCRIPT_NAME in the postback URL" do
        (@doc/'form').first.attributes["action"].value.should == "/foo/login"
      end

      it "includes SCRIPT_NAME in the CSS URL" do
        (@doc/'link[rel="stylesheet"]').first.attributes["href"].value.should == "/foo/login.css"
      end

      it "can render a failure message" do
        @doc = Nokogiri.HTML(@provider.login_html({}, { :show_failure => true }))

        (@doc/'.error').first.inner_html.should == 'Login failed'
      end
    end

    describe "#login_css" do
      it "provides CSS for the login form" do
        expected_css = File.read(File.join(File.dirname(__FILE__),
                                           %w(.. .. .. .. .. assets bcsec modes middleware form login.css)))

        @provider.login_css.should == expected_css
      end
    end
  end
end
