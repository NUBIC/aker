require File.expand_path('../../spec_helper', __FILE__)

module Aker
  describe Cas::Slice do
    let(:configuration) { Configuration.new(:slices => [Cas::Slice.new]) }

    it "registers the cas authority" do
      configuration.authority_aliases[:cas].should be Aker::Cas::Authority
    end

    it 'registers the cas interactive mode' do
      configuration.registered_modes.should include(Aker::Cas::ServiceMode)
    end

    it 'registers the cas proxy mode' do
      configuration.registered_modes.should include(Aker::Cas::ProxyMode)
    end
  end
end
