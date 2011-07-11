require File.expand_path('../../../spec_helper', __FILE__)
require 'rack/test'

module Bcsec::Rack
  describe SessionTimer do
    let(:app) { stub.as_null_object }
    let(:configuration) { Bcsec::Configuration.new }
    let(:env) { { 'bcsec.configuration' => configuration, 'rack.session' => session } }
    let(:expected_timeout) { 600 }
    let(:session) { {} }
    let(:timer) { SessionTimer.new(app) }

    before do
      configuration.add_parameters_for(:policy, %s(session-timeout-seconds) => expected_timeout)
    end

    describe "#call" do
      let(:current_request_time) { 1234567890 }

      before do
        Time.stub!(:now => Time.at(current_request_time))
      end

      it "sets bcsec.timeout_at" do
        timer.call(env)

        env['bcsec.timeout_at'].should == current_request_time + expected_timeout
      end

      context 'if no session timeout is given' do
        before do
          configuration.add_parameters_for(:policy, %s(session-timeout-seconds) => nil)
        end

        it 'passes control down the Rack stack' do
          app.should_receive(:call)

          timer.call(env)
        end
      end

      context 'if no last request timestamp is present' do
        before do
          session['bcsec.last_request_at'] = nil
        end

        it 'sets last request time to the current request time' do
          timer.call(env)

          session['bcsec.last_request_at'].should == current_request_time
        end

        it 'passes control down the Rack stack' do
          app.should_receive(:call)

          timer.call(env)
        end
      end

      context 'if a last request timestamp is present' do
        context 'and the current request is within the timeout window' do
          before do
            #
            # The below calculation places the current request time in the
            # middle of the session timeout window:
            #
            #     prv    cur
            #      |      |
            #      |------|
            #      |e.t./2|
            #      |------------
            #      |    e.t.
            #
            session['bcsec.last_request_at'] = current_request_time - (expected_timeout / 2)
          end

          it 'sets the last request timestamp' do
            timer.call(env)

            session['bcsec.last_request_at'].should == current_request_time
          end

          it 'passes control down the Rack stack' do
            app.should_receive(:call)

            timer.call(env)
          end
        end

        context 'and the current request is outside the timeout window' do
          before do
            #
            # The below calculation places the current request time at the edge
            # of the session timeout window:
            #
            #     prv          cur
            #      |            |
            #      |------------|
            #      |    e.t.    |
            #
            session['bcsec.last_request_at'] = current_request_time - expected_timeout
          end

          it 'does not pass control down the Rack stack' do
            app.should_not_receive(:call)

            timer.call(env)
          end

          it 'logs the user out' do
            resp = timer.call(env)

            resp[0].should == 302
            resp[1].should include('Location' => '/logout')
          end
        end
      end
    end
  end
end
