require File.expand_path('../../spec_helper', __FILE__)

module Aker
  describe Ldap::Slice do
    let(:configuration) { Aker::Configuration.new(:slices => [Ldap::Slice.new]) }

    it 'registers :ldap as an alias for the LDAP authority' do
      configuration.authority_aliases[:ldap].should be Aker::Ldap::Authority
    end
  end
end
