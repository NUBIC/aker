require File.expand_path('../../spec_helper', __FILE__)

module Aker
  describe Form::Slice do
    let(:configuration) { Configuration.new(:slices => [Form::Slice.new]) }

    it 'registers the cas proxy mode' do
      configuration.registered_modes.should include(Aker::Form::Mode)
    end
  end
end
