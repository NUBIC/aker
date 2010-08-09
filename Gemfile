source :rubygems
source 'http://download.bioinformatics.northwestern.edu/gems/'

gem 'activesupport', '~> 2.3.5'
gem 'rubytree', '~> 0.7.0'

# pers
gem 'activerecord', '~> 2.3.5'
gem 'schema_qualified_tables', '~> 1.0'
gem 'bcdatabase', '~> 1.0'
gem 'composite_primary_keys', '~> 2.3.5', :require => nil

# netid
gem 'ruby-net-ldap', '>= 0.0.4'

# cas
gem 'rubycas-client', '~> 2.1.0'

# modes
gem 'warden', '~> 0.10.3'

group :development do
  # general testing
  gem 'cucumber', '~> 0.6.0'
  gem 'rack-test', '~> 0.5'
  gem 'mechanize', '~> 1.0'
  gem 'rspec', '~> 1.3'

  platforms :ruby_19 do
    gem 'test-unit', '1.2.3'
  end

  gem 'rcov', '~> 0.9'
  gem 'rest-client', '~> 1.4.0'
  gem 'ZenTest'

  # docs
  gem 'yard', '~> 0.5.8'
  # for yard
  platforms :jruby do
    gem 'maruku'
  end

  platforms :ruby_18, :ruby_19 do
    gem 'rdiscount'
  end

  gem 'fssm'

  # metrics
  gem 'saikuro_treemap', '0.1.2'

  # pers testing
  platforms :ruby_18, :ruby_19 do
    gem 'ruby-oci8', '~> 2.0'
  end
  gem 'activerecord-oracle_enhanced-adapter', '~> 1.2'

  platforms :jruby do
    # This is to keep JRuby from complaining when bcdatabase loads highline
    gem 'ffi-ncurses'
    gem 'jdbc-sqlite3'
    gem 'activerecord-jdbcsqlite3-adapter'
  end

  gem 'database_cleaner', '~> 0.5', :require => nil

  platforms :ruby_18, :ruby_19 do
    gem 'sqlite3-ruby'
  end

  gem 'bcoracle', '~>1.0'

  platforms :ruby_19 do
    gem 'unicode_utils'
  end

  # cas testing
  gem 'markaby', '0.5'    # other versions break RubyCAS-Server
  gem 'rubycas-server'

  # ci & deployment
  gem 'net-ssh', '~> 2.0'
  gem 'net-scp', '~> 1.0'
  gem 'nokogiri'
  gem 'rake', '>= 0.8.7'
  gem 'ci_reporter', '~> 1.6'

  platforms :jruby do
    gem 'jruby-openssl'
  end
end
