require File.expand_path("../../../../spec_helper", __FILE__)
require File.expand_path('../a_form_login_responder', __FILE__)
require "rack/test"

module Aker::Form::Middleware
  describe CustomViewLoginResponder do
    let(:responder_middleware_class) { Aker::Form::Middleware::CustomViewLoginResponder }

    it_behaves_like 'a form login responder'

    include_context 'login responder context'

    describe "#call" do
      let(:warden) { mock }

      before do
        env.update("warden" => warden, "REQUEST_METHOD" => "POST")
      end

      describe "when authentication failed" do
        before do
          warden.stub(:authenticated? => false, :custom_failure! => nil)

          post login_path,
            {'username' => 'jo', 'password' => 'wrong'},
            env
        end

        def recorded_env
          captured_env.first
        end

        it "adds the login failed flag to the environment" do
          recorded_env['aker.form.login_failed'].should == true
        end

        it "adds the attempted username to the environment" do
          recorded_env['aker.form.username'].should == 'jo'
        end

        it 'calls the app' do
          last_response.body.should == "Hello"
        end
      end
    end
  end
end
