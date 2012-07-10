module AugeasSpec
end

require 'augeas_spec/fixtures'

RSpec.configure do |config|
  config.extend AugeasSpec::Fixtures
  config.include AugeasSpec::Fixtures

  config.before :each do
    Puppet::Util::Storage.stubs(:store)
  end
end
