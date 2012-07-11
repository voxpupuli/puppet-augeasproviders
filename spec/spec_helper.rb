require 'pathname'
dir = Pathname.new(__FILE__).parent
$LOAD_PATH.unshift(dir, dir + 'lib', dir + '../lib')

require 'rubygems'

require 'simplecov'
SimpleCov.start

require 'puppetlabs_spec_helper/module_spec_helper'
require 'augeas_spec'

RSpec.configure do |config|
  config.mock_with :mocha
end
