lib_root = File.join(File.dirname(__FILE__), %w(.. lib))

if File.exist?(File.join(lib_root, 'bcsec.rb'))
  $stderr.puts 'Loading bcsec from source tree'

  $LOAD_PATH.unshift(lib_root)
else
  $stderr.puts 'Loading bcsec from Rubygems'

  require 'rubygems'

  gem 'bcsec', '~> 2'
end

require 'bcsec'
