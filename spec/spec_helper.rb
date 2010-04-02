require File.expand_path("../../vendor/gems/environment", __FILE__)

require "spec"

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

require 'bcsec/deprecation'
module Bcsec::Deprecation
  class TestMode
    def messages
      @messages ||= []
    end

    def report(level, message, version)
      messages << { :level => level, :message => message, :version => version }
    end

    def reset
      @messages = nil
    end

    def fail_if_any_very_obsolete
      obs = messages.select { |m| very_obsolete?(m[:version]) }
      unless obs.empty?
        fail "Very obsolete code still present.  Remove it and its specs.\n" <<
          "- #{obs.collect { |o| o[:message] }.join("\n- ")}"
      end
    end

    def very_obsolete?(version)
      # "very obsolete" if it was deprecated at least two minor
      # versions ago
      major_minor(Bcsec::VERSION) - Rational(2, 10) >= major_minor(version)
    end

    def major_minor(version)
      Rational(version.split('.')[0, 2].inject(0) { |s, i| s = s * 10 + i.to_i }, 10)
    end
  end
end

require File.expand_path('../database_helper', __FILE__)

Spec::Runner.configure do |config|
  config.before(:each) do
    @original_deprecation_mode, Bcsec::Deprecation.mode =
      Bcsec::Deprecation.mode, Bcsec::Deprecation::TestMode.new
  end

  config.after(:each) do
    Bcsec::Deprecation.mode.fail_if_any_very_obsolete
    Bcsec::Deprecation.mode = @original_deprecation_mode
  end

  Bcsec::Spec::DatabaseData.use_in(config)
end
