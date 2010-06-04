begin
  require File.join(File.dirname(__FILE__), %w(vendor gems environment))
rescue LoadError
  abort 'Run gem bundle first.'
end
