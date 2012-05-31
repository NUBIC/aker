source :rubygems

gemspec

# for testing against different releases of ActiveSupport
if ENV['ACTIVESUPPORT_VERSION']
  version = case ENV['ACTIVESUPPORT_VERSION']
            when 'as_2.3' then '~> 2.3.0'
            when 'as_3.0' then '~> 3.0.10'
            when 'as_3.1' then '~> 3.1.0'
            when 'as_3.2' then '~> 3.2.0'
            else raise "Unknown ActiveSupport version #{ENV['ACTIVESUPPORT_VERSION']}"
            end

  gem 'activesupport', version
  # This is a hint for bundler that prevents one form of infinite
  # resolution time when version is 3.0.x. It is harmless otherwise.
  gem 'activerecord', version
end

group :development do
  # general testing
  gem 'cucumber', '~> 0.10.0'
  gem 'rack-test', '~> 0.5'
  gem 'mechanize', '~> 1.0'
  gem 'rspec', '~> 2.6.0' # 2.7.0 doesn't work in CI due to #476 and #477

  gem 'rcov', '~> 0.9'
  gem 'rest-client', '~> 1.4.0'
  # Later versions of ZenTest require rubygems 1.8.x, which does not seem to work
  # with JRuby
  gem 'ZenTest', '~> 4.5.0'

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

  # ldap testing
  gem 'ladle', '~> 0.2'

  # cas testing
  # although we use activerecord directly, declaring it here without a
  # version causes one form of infinite resolving in bundler.
  # gem 'activerecord'
  gem 'rubycas-server', :require => 'casserver',
    :git => 'git://github.com/NUBIC/rubycas-server.git', :ref => 'cedf6cd'
  gem 'sinatra', '~> 1.2.0', :require => false
  platforms :jruby do
    gem 'jdbc-sqlite3'
    gem 'activerecord-jdbcsqlite3-adapter', '~> 1.1'
  end
  platforms :ruby_18, :ruby_19 do
    gem 'sqlite3'
  end

  # ci & deployment
  gem 'nokogiri'
  gem 'rake', '>= 0.9.0'
  gem 'ci_reporter', '~> 1.6'
  gem 'bundler', '~> 1.0'

  platforms :jruby do
    gem 'jruby-openssl'
  end
end
