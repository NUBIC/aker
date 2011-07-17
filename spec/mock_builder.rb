module Bcsec
  module Spec
    ##
    # A record-only version of Rack::Builder.
    class MockBuilder
      def reset!
        self.uses.clear
      end

      def use(cls, *params, &block)
        self.uses << [cls, params, block]
      end

      def uses
        @uses ||= []
      end

      def using?(klass, *params)
        self.uses.detect { |cls, prms, block| cls == klass && params == prms }
      end

      alias :find_use_of :using?
    end
  end
end
