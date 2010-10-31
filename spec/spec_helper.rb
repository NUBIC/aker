require 'bundler'
Bundler.setup

require "spec"
require 'spec/test/unit'

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

require 'bcsec'

require File.expand_path('../database_helper', __FILE__)
require File.expand_path('../deprecation_helper', __FILE__)
require File.expand_path('../logger_helper', __FILE__)
require File.expand_path("../../tool-patches/rcov-encoding-1.9.rb", __FILE__)

if RUBY_PLATFORM == 'java'
  require File.expand_path('../java_helper', __FILE__)
end

Spec::Runner.configure do |config|
  Bcsec::Spec::DatabaseData.use_in(config)
  Bcsec::Spec::DeprecationMode.use_in(config)
  config.include Bcsec::Spec::LoggerHelper
end

def port_offset
  case ENV["BCSEC_ENV"]
  when /jruby/
    108
  when /1.9.1/
    207
  else
    0
  end
end
