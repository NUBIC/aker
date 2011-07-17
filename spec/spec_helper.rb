require 'bundler'
Bundler.setup

require 'rspec'

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

require 'bcsec'

require File.expand_path('../database_helper', __FILE__)
require File.expand_path('../deprecation_helper', __FILE__)
require File.expand_path('../logger_helper', __FILE__)
require File.expand_path("../../tool-patches/rcov-encoding-1.9.rb", __FILE__)
require File.expand_path('../mock_builder', __FILE__)

# Round-about require so that this will continue to work after purging
# pers but before doing manual edits.
File.expand_path('../pers_helper.rb', __FILE__).tap do |path|
  require path if File.exist?(path)
end

if RUBY_PLATFORM == 'java'
  require File.expand_path('../java_helper', __FILE__)
end

RSpec.configure do |config|
  Bcsec::Spec::DatabaseData.use_in(config)
  Bcsec::Spec::DeprecationMode.use_in(config)
  config.include Bcsec::Spec::LoggerHelper

  config.treat_symbols_as_metadata_keys_with_true_values = true

  config.after do
    FileUtils.rm_rf @tmpdir if @tmpdir
  end

  def tmpdir
    @tmpdir ||= File.expand_path('../../tmp/bcsec-unit-tests', __FILE__).
      tap { |p| FileUtils.mkdir_p p }
  end
end

def port_offset
  case ENV["BCSEC_ENV"]
  when /jruby/
    108
  when /1.9/
    207
  else
    0
  end
end
