# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'aker/version'

Gem::Specification.new do |s|
  s.name = 'aker'
  s.version = Aker::VERSION
  s.platform = Gem::Platform::RUBY
  s.summary = "Bioinformatics core security infrastructure library"

  s.require_path = 'lib'
  s.files = Dir.glob("{CHANGELOG,README,VERSION,{assets,lib,spec}/**/*}")
  s.authors = ["Rhett Sutphin", "David Yip"]
  s.email = "r-sutphin@northwestern.edu"
  s.homepage = "https://code.bioinformatics.northwestern.edu/redmine/projects/show/aker-ruby"

  # general
  s.add_dependency 'rubytree', '~> 0.7.0'
  s.add_dependency 'activesupport', '>= 2.3.0'

  # ldap
  s.add_dependency 'net-ldap', '~> 0.1.1'

  # cas
  s.add_dependency 'castanet', '~> 1.0.0'

  # rack integration & modes
  s.add_dependency 'warden', '~> 1.0'
end
