require File.expand_path('../../spec_helper', __FILE__)

module Bcsec
  describe Authorities::Slice do
    let(:configuration) { Configuration.new(:slices => [Authorities::Slice.new]) }

    it "registers the cas authority" do
      configuration.authority_aliases[:cas].should be Bcsec::Authorities::Cas
    end

    it "registers the static authority" do
      configuration.authority_aliases[:static].should be Bcsec::Authorities::Static
    end

    it "registers the automatic_access authority" do
      configuration.authority_aliases[:automatic_access].
        should be Bcsec::Authorities::AutomaticAccess
    end
  end
end
