require File.expand_path('../../spec_helper', __FILE__)

module Aker
  describe Authorities::Slice do
    let(:configuration) { Configuration.new(:slices => [Authorities::Slice.new]) }

    it "registers the static authority" do
      configuration.authority_aliases[:static].should be Aker::Authorities::Static
    end

    it "registers the automatic_access authority" do
      configuration.authority_aliases[:automatic_access].
        should be Aker::Authorities::AutomaticAccess
    end
  end
end
