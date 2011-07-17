require File.expand_path("../../../../spec_helper", __FILE__)
require 'nokogiri'

module Aker::Modes::Support
  describe LoginFormAssetProvider do
    let(:vessel) do
      Object.new.tap { |o| o.extend(LoginFormAssetProvider) }
    end

    describe "#login_html" do
      before do
        env = { 'SCRIPT_NAME' => '/foo' }
        @doc = Nokogiri.HTML(vessel.login_html(env))
      end

      it "includes SCRIPT_NAME in the postback URL" do
        (@doc/'form').first.attributes["action"].value.should == "/foo/login"
      end

      it "includes SCRIPT_NAME in the CSS URL" do
        (@doc/'link[rel="stylesheet"]').first.attributes["href"].value.should == "/foo/login/login.css"
      end

      it "can render a 'login failed' message" do
        @doc = Nokogiri.HTML(vessel.login_html({}, { :login_failed => true }))

        (@doc/'.error').first.inner_html.should == 'Login failed'
      end

      it "can render a 'logged out' message" do
        @doc = Nokogiri.HTML(vessel.login_html({}, { :logged_out => true }))

        (@doc/'h1').first.inner_html.should == 'Logged out'
      end

      it "can render text in the username text field" do
        @doc = Nokogiri.HTML(vessel.login_html({}, { :username => "user" }))

        (@doc/'input[name="username"]').first['value'].should == 'user'
      end

      it "can store a URL to go to after login succeeds" do
        @doc = Nokogiri.HTML(vessel.login_html({}, { :url => 'http://www.example.edu' }))

        (@doc/'input[name="url"]').first['value'].should == 'http://www.example.edu'
      end

      it "escapes HTML in usernames" do
        html = vessel.login_html({}, { :username => "user<a/>" })

        # Annoyingly, Nokogiri.HTML automatically unescapes escaped entities in
        # attribute values.
        html.should include("user&lt;a&#x2F;&gt;");
        html.should_not include("user<a/>")
      end
    end

    describe "#login_css" do
      it "provides CSS for the login form" do
        expected_css = File.read(File.join(File.dirname(__FILE__),
                                           %w(.. .. .. .. assets aker modes middleware form login.css)))

        vessel.login_css.should == expected_css
      end
    end
  end
end