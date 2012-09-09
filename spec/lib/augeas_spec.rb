module AugeasSpec
  class Error < StandardError
  end
end

require 'augeasproviders/provider'
dir = File.expand_path(File.dirname(__FILE__))
AugeasProviders::Provider.loadpath = File.join(dir, '../../augeas/lenses')

require 'augeas_spec/augparse'
require 'augeas_spec/fixtures'

RSpec.configure do |config|
  config.extend AugeasSpec::Augparse
  config.extend AugeasSpec::Fixtures
  config.include AugeasSpec::Augparse
  config.include AugeasSpec::Fixtures

  config.before :each do
    Puppet::Util::Storage.stubs(:store)
  end
end
