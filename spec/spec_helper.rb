require 'bundler'
Bundler.setup

require 'rspec'

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

require 'aker'

require File.expand_path('../deprecation_helper', __FILE__)
require File.expand_path('../logger_helper', __FILE__)
require File.expand_path("../../tool-patches/rcov-encoding-1.9.rb", __FILE__)
require File.expand_path('../mock_builder', __FILE__)

if RUBY_PLATFORM == 'java'
  require File.expand_path('../java_helper', __FILE__)
end

RSpec.configure do |config|
  Aker::Spec::DeprecationMode.use_in(config)
  config.include Aker::Spec::LoggerHelper

  config.treat_symbols_as_metadata_keys_with_true_values = true

  config.after do
    FileUtils.rm_rf @tmpdir if @tmpdir
  end

  def tmpdir
    @tmpdir ||= File.expand_path('../../tmp/aker-unit-tests', __FILE__).
      tap { |p| FileUtils.mkdir_p p }
  end
end

# TODO: uses of this should probably be replaced with something that
# finds a random open port instead
def port_offset
  base = case ENV['CI_RUBY']
         when nil
           0
         when /jruby/
           17
         when /1.9/
           13
         when /1.8/
           31
         when /2.0/
           37
         else
           fail "Unexpected CI_RUBY value: #{ENV['CI_RUBY'].inspect}"
         end
  case ENV["ACTIVESUPPORT_VERSION"]
  when nil
    base * 1
  when /3.2/
    base * 23
  when /3.1/
    base * 19
  when /3.0/
    base * 5
  when /2.3/
    base * 7
  when /4.0/
    base * 29
  else
    fail "Unsupported ActiveSupport version #{ENV['ACTIVESUPPORT_VERSION'].inspect}"
  end
end
