source :rubygems
source 'http://download.bioinformatics.northwestern.edu/gems/'

gemspec

# for testing against different releases of ActiveRecord
if ENV['ACTIVERECORD_VERSION']
  version = case ENV['ACTIVERECORD_VERSION']
            when 'ar_2.3' then '~> 2.3.0'
            when 'ar_3.0' then '~> 3.0'
            else raise "Unknown ActiveRecord version #{ENV['ACTIVERECORD_VERSION']}"
            end

  gem 'activerecord', version
end

# until bcdatabase 1.0.3 is released
gem 'bcdatabase', :git => 'https://github.com/rsutphin/bcdatabase.git'

group :development do
  # general testing
  gem 'cucumber', '~> 0.6.0'
  gem 'rack-test', '~> 0.5'
  gem 'mechanize', '~> 1.0'
  gem 'rspec', '~> 2.0.1'

  platforms :ruby_19 do
    gem 'test-unit', '1.2.3'
  end

  gem 'rcov', '~> 0.9'
  gem 'rest-client', '~> 1.4.0'
  gem 'ZenTest'

  # docs
  gem 'yard', '~> 0.6.1'
  # for yard
  platforms :jruby do
    gem 'maruku'
  end

  platforms :ruby_18, :ruby_19 do
    gem 'rdiscount'
  end

  # metrics
  gem 'saikuro_treemap', '0.1.2'

  # pers testing
  platforms :ruby_18, :ruby_19 do
    gem 'ruby-oci8', '~> 2.0'
  end

  platforms :jruby do
    # This is to keep JRuby from complaining when bcdatabase loads highline
    gem 'ffi-ncurses'
    gem 'jdbc-sqlite3'
    gem 'activerecord-jdbcsqlite3-adapter'
  end

  # database_cleaner 0.6 doesn't work due to
  # http://github.com/bmabey/database_cleaner/issues/23
  # 0.5.2 doesn't work on JRuby due to a variation on
  # http://github.com/bmabey/database_cleaner/issues/11
  gem 'database_cleaner', '= 0.5', :require => nil

  platforms :ruby_18, :ruby_19 do
    gem 'sqlite3-ruby', '~> 1.2.0'
  end

  gem 'bcoracle', '~> 1.1'

  platforms :ruby_19 do
    gem 'unicode_utils'
  end

  # netid testing
  gem 'ladle', '~> 0.2'

  # cas testing
  gem 'markaby', '0.5'    # other versions break RubyCAS-Server
  gem 'picnic', :git => 'git+ssh://code.bioinformatics.northwestern.edu/git/picnic.git', :branch => 'activesupport3'
  gem 'rubycas-server'

  # ci & deployment
  gem 'net-ssh', '~> 2.0'
  gem 'net-scp', '~> 1.0'
  gem 'nubic-gem-tasks', '~> 1.0'
  gem 'nokogiri'
  gem 'rake', '>= 0.8.7'
  gem 'ci_reporter', '~> 1.6'

  platforms :jruby do
    gem 'jruby-openssl'
  end
end
