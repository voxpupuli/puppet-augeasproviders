source 'https://rubygems.org'

if ENV.key?('PUPPET')
  puppetversion = "~> #{ENV['PUPPET']}"
else
  puppetversion = ['>= 2.6']
end
gem 'puppet', puppetversion

if ENV.key?('RUBY_AUGEAS')
  if ENV['RUBY_AUGEAS'] == '0.3.0'
    # pre-0.4.1 versions aren't available on rubygems
    rbaugversion = {:git => 'git://github.com/domcleal/ruby-augeas.git', :branch => '0.3.0-gem'}
  else
    rbaugversion = "~> #{ENV['RUBY_AUGEAS']}"
  end
else
  rbaugversion = ['~> 0.3']
end
gem 'ruby-augeas', rbaugversion

group :development do
  gem 'puppet-lint'
  gem 'puppetlabs_spec_helper', '>= 0.4.1'
  gem 'rake'
  gem 'rspec-puppet'
  gem 'simplecov'
  gem 'yard'
  gem 'redcarpet', '~> 2.0'
  gem 'pry'
end
