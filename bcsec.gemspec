# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'bcsec/version'

Gem::Specification.new do |s|
  s.name = 'bcsec'
  s.version = Bcsec::VERSION
  s.platform = Gem::Platform::RUBY
  s.summary = "Bioinformatics core security infrastructure library"

  s.require_path = 'lib'
  s.files = Dir.glob("{CHANGELOG,README,VERSION,{assets,lib,spec}/**/*}")
  s.authors = ["Rhett Sutphin", "David Yip"]
  s.email = "r-sutphin@northwestern.edu"
  s.homepage = "https://code.bioinformatics.northwestern.edu/redmine/projects/show/bcsec-ruby"

  # general
  s.add_dependency 'rubytree', '~> 0.7.0'

  # pers
  s.add_dependency 'activerecord', '>= 2.3.0'
  s.add_dependency 'schema_qualified_tables', '~> 1.0'
  s.add_dependency 'bcdatabase', '~> 1.0'
  s.add_dependency 'composite_primary_keys'
  s.add_dependency 'bcaudit', '~> 0.2'
  s.add_dependency 'activerecord-oracle_enhanced-adapter', '~> 1.3.0'

  # netid
  s.add_dependency 'net-ldap', '~> 0.1.1'

  # cas
  s.add_dependency 'castanet', '~> 1.0.0'

  # modes
  s.add_dependency 'warden', '~> 1.0'
end
