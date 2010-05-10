# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'bcsec'

# Evaluates a gemfile and appends the deps to a gemspec.
# Later versions of bundler may have a method for this.
class GemfileGemspecDeps
  def initialize(gemspec)
    @spec = gemspec
    instance_eval(File.read('Gemfile'))
  end

  def gem(name, version=[], *ignored)
    if @only && @only.include?(:development)
      @spec.add_development_dependency(name, *version)
    else
      @spec.add_runtime_dependency(name, *version)
    end
  end

  def only(*envs)
    @only = envs
    yield
    @only = nil
  end

  def method_missing(msg, *args)
    # do nothing for unimplemented bits
  end
end

Gem::Specification.new do |s|
  s.name = 'bcsec'
  s.version = Bcsec::VERSION
  s.platform = Gem::Platform::RUBY
  s.summary = "Bioinformatics core security infrastructure library"

  GemfileGemspecDeps.new(s)

  s.require_path = 'lib'
  s.files = Dir.glob("{CHANGELOG,README,VERSION,{assets,lib,spec}/**/*}")
  s.authors = ["Rhett Sutphin", "David Yip"]
  s.email = "r-sutphin@northwestern.edu"
  s.homepage = "https://code.bioinformatics.northwestern.edu/redmine/projects/bcsec-ruby"
end

