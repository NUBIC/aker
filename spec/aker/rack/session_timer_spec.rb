require File.expand_path('../../../spec_helper', __FILE__)
require 'rack/test'

module Aker::Rack
  describe SessionTimer do
    let(:app) { double.as_null_object }
    let(:configuration) { Aker::Configuration.new { rack_parameters :logout_path => '/a/logout' } }
    let(:env) {
      {
        'aker.configuration' => configuration,
        'rack.session' => session,
        'warden' => warden
      }
    }
    let(:expected_timeout) { 600 }
    let(:session) { {} }
    let(:timer) { SessionTimer.new(app) }
    let(:warden) { double }

    before do
      configuration.add_parameters_for(:policy, %s(session-timeout-seconds) => expected_timeout)
    end

    describe "#call" do
      let(:current_request_time) { 1234567890 }

      before do
        Time.stub(:now => Time.at(current_request_time))
      end

      it "sets aker.timeout_at" do
        timer.call(env)

        env['aker.timeout_at'].should == current_request_time + expected_timeout
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
          session['aker.last_request_at'] = nil
        end

        it 'sets last request time to the current request time' do
          timer.call(env)

          session['aker.last_request_at'].should == current_request_time
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
            session['aker.last_request_at'] = current_request_time - (expected_timeout / 2)
          end

          it 'sets the last request timestamp' do
            timer.call(env)

            session['aker.last_request_at'].should == current_request_time
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
            session['aker.last_request_at'] = current_request_time - expected_timeout

            warden.stub(:logout)
          end

          it 'passes control down the Rack stack' do
            app.should_receive(:call)

            timer.call(env)
          end

          it 'resets the session' do
            warden.should_receive(:logout)

            timer.call(env)
          end

          it 'sets the session expired flag in the environment' do
            timer.call(env)

            env['aker.session_expired'].should == true
          end
        end
      end
    end
  end
end
