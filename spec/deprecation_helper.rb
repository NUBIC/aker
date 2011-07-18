module Aker
  module Spec
    class DeprecationMode
      def self.use_in(spec_config)
        spec_config.include DeprecationHelper

        spec_config.before(:each) do
          @original_deprecation_mode, Aker::Deprecation.mode =
            Aker::Deprecation.mode, Aker::Spec::DeprecationMode.new
        end

        spec_config.after(:each) do
          begin
            Aker::Deprecation.mode.fail_if_any_very_obsolete
          ensure
            Aker::Deprecation.mode = @original_deprecation_mode
          end
        end
      end

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
        major_minor(Aker::VERSION) - Rational(2, 10) >= major_minor(version)
      end

      def major_minor(version)
        Rational(version.split('.')[0, 2].inject(0) { |s, i| s = s * 10 + i.to_i }, 10)
      end
    end

    module DeprecationHelper
      def deprecation_message(n=0)
        (Aker::Deprecation.mode.messages[n] || {})[:message]
      end
    end
  end
end
