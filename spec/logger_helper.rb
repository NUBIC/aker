module Bcsec
  module Spec
    module LoggerHelper
      def actual_log
        unless @log_io
          raise "You don't seem to be using the spec logger.  Is it in your bcsec configuration?"
        end
        @log_io.string
      end

      def spec_logger
        @log_io = StringIO.new
        @spec_logger ||= Logger.new(@log_io)
      end
    end
  end
end
