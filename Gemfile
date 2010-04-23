disable_system_gems
source 'http://download.bioinformatics.northwestern.edu/gems/'

if RUBY_PLATFORM == 'java'
  bin_path 'jgem_bin'
else
  bin_path 'gem_bin'
end

gem 'activesupport', '~> 2.3.5'
gem 'rubytree', '~> 0.6.0'

# pers
gem 'activerecord', '~> 2.3.5'
gem 'schema_qualified_tables', '~> 1.0'
gem 'composite_primary_keys', '~> 2.3.5', :require_as => 'date' # no nil

# netid
gem 'ruby-net-ldap', '>= 0.0.4'

# modes
gem 'warden', '~> 0.10.3'

only :development do
  gem 'capybara'
  gem 'cucumber', '~> 0.6'
  gem 'rack-test', '~> 0.5'
  gem 'rspec', '~> 1.3'
  gem 'rcov', '~> 0.9'
  gem 'yard', '~> 0.5'
  # for yard; doesn't work in jruby
  gem 'bluecloth' unless RUBY_PLATFORM == 'java'
  gem 'fssm'

  gem 'ruby-oci8', '~> 2.0' unless RUBY_PLATFORM == 'java'
  gem 'activerecord-oracle_enhanced-adapter', '~> 1.2'
  gem 'bcdatabase', '~> 1.0'
  # This is to keep JRuby from complaining when bcdatabase loads highline
  gem 'ffi-ncurses' if RUBY_PLATFORM == 'java'
  gem 'database_cleaner', '~> 0.5', :require_as => 'date' # no nil
  if RUBY_PLATFORM == 'java'
    gem 'jdbc-sqlite3'
    gem 'activerecord-jdbcsqlite3-adapter'
  else
    gem 'sqlite3-ruby'
  end
  gem 'bcoracle', '~>1.0'

  gem 'net-ssh', '~> 2.0'
  gem 'net-scp', '~> 1.0'
  gem 'nokogiri'
  gem 'rake', '>= 0.8.7'
  gem 'ci_reporter', '~> 1.6'
  gem 'jruby-openssl' if RUBY_PLATFORM == 'java'
end
