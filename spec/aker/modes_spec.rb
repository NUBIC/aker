require File.expand_path('../../spec_helper', __FILE__)

module Aker
  describe Modes::Slice do
    let(:configuration) { Configuration.new(:slices => [Modes::Slice.new]) }

    it "registers the form mode" do
      configuration.registered_modes.should include(Aker::Modes::Form)
    end

    it "registers the basic mode" do
      configuration.registered_modes.should include(Aker::Modes::HttpBasic)
    end

    it "registers the cas mode" do
      configuration.registered_modes.should include(Aker::Modes::Cas)
    end

    it "registers the cas proxy mode" do
      configuration.registered_modes.should include(Aker::Modes::CasProxy)
    end
  end
end
