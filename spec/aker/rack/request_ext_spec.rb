require File.expand_path('../../../spec_helper', __FILE__)

require 'rack'

module Aker::Rack
  describe RequestExt do
    let(:request_class) do
      Class.new(Rack::Request) do
        include RequestExt
      end
    end

    let(:request) { request_class.new({}) }

    describe '#interactive?' do
      it 'returns true if the request is interactive' do
        request.env['aker.interactive'] = true

        request.should be_interactive
      end

      it 'returns false if the request is non-interactive' do
        request.env['aker.interactive'] = false

        request.should_not be_interactive
      end
    end
  end
end
