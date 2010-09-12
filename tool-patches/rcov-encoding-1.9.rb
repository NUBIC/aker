# Monkey patch for rcov's broken encoding handling on 1.9
# From
# http://codefluency.com/post/1023734493/a-bandaid-for-rcov-on-ruby-1-9
# Needed in rcov-0.9.8; possibly not in later versions.
if defined?(Rcov)
  class Rcov::CodeCoverageAnalyzer
    def update_script_lines__
      if '1.9'.respond_to?(:force_encoding)
        SCRIPT_LINES__.each do |k,v|
          v.each { |src| src.force_encoding('utf-8') }
        end
      end
      @script_lines__ = @script_lines__.merge(SCRIPT_LINES__)
    end
  end
end
