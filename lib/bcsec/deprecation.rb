require 'bcsec'
require 'rubygems/version'

module Bcsec
  module Deprecation
    class << self
      attr_reader :test_messages
      attr_accessor :mode

      def mode
        @mode ||= default_mode
      end

      def default_mode
        StderrMode.new
      end

      def notify(message, version)
        level = determine_level(version)
        mode.report(level,
                    full_message_for(level, message, version, caller[1].split('/').last),
                    version)
      end

      def determine_level(version)
        if Gem::Version.new(version) <= Gem::Version.new(Bcsec::VERSION)
          :obsolete
        else
          :deprecated
        end
      end

      def full_message_for(level, message, version, line)
        sprintf "%s: #{message}  %s  (Called from #{line}.)" %
          (case level
           when :deprecated
             ["DEPRECATION WARNING",
              "It will be removed from bcsec in version #{version} or later."]
           when :obsolete
             ["OBSOLETE API USED",
              "It is no longer functional as of bcsec #{version} " <<
              "and could be removed in any future version."]
           else
             raise "Unexpected level: #{level.inspect}"
           end)
      end
    end

    class StderrMode
      def report(level, message, version)
        case level
        when :deprecated; $stderr.puts message;
        when :obsolete: raise ObsoleteError, message
        end
      end
    end

    class ObsoleteError < StandardError; end
  end
end
