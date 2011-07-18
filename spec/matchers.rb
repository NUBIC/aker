module Aker
  module Spec
    module Matchers
      class AllMatch
        def initialize(pattern)
          @expected = pattern
        end

        def matches?(target)
          target.each_with_index do |actual, i|
            @at = i

            break false unless actual =~ @expected
          end
        end

        def failure_message_for_should
          "expected element #{@at} to match #{@expected.inspect}"
        end

        def failure_message_for_should_not
          "expected element #{@at} to not match #{@expected.inspect}"
        end
      end

      def all_match(expected)
        AllMatch.new(expected)
      end
    end
  end
end
