require File.expand_path("../../../../spec_helper", __FILE__)
require File.expand_path('../a_form_login_responder', __FILE__)
require "rack/test"

module Aker::Form::Middleware
  describe LoginResponder do
    let(:responder_middleware_class) { Aker::Form::Middleware::LoginResponder }

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
        end

        it "renders a 'login failed' message" do
          post login_path, {}, env

          last_response.status.should == 401
          last_response.body.should include("Login failed")
        end
      end
    end
  end
end
