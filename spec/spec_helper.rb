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

def port_offset
  base = case ENV["AKER_ENV"]
         when /jruby/
           108
         when /1.9/
           207
         when /1.8/
           306
         else
           0
         end
  case ENV["ACTIVESUPPORT_VERSION"]
  when /3.0/
    base * 6
  when /2.3/
    base
  else
    base * 0
  end
end
