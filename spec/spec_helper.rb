# frozen_string_literal: true

# Managed by modulesync - DO NOT EDIT
# https://voxpupuli.org/docs/updating-files-managed-with-modulesync/

# puppetlabs_spec_helper will set up coverage if the env variable is set.
# We want to do this if lib exists and it hasn't been explicitly set.
ENV['COVERAGE'] ||= 'yes' if Dir.exist?(File.expand_path('../lib', __dir__))

require 'voxpupuli/test/spec_helper'

require 'rubygems'


require 'simplecov'
SimpleCov.start do
  add_group "AugeasProviders Libs", "/lib/augeasproviders/"
  add_group "Puppet Types", "/lib/puppet/type/"
  add_group "Puppet Providers", "/lib/puppet/provider/"
  add_group "Augeas Spec Lib", "/spec/lib/"

  add_filter "/spec/fixtures/"
  add_filter "/spec/unit/"
  add_filter "/spec/support/"
end

require 'augeas_spec'

RSpec.configure do |c|
  c.facterdb_string_keys = false
end

add_mocked_facts!

if File.exist?(File.join(__dir__, 'default_module_facts.yml'))
  facts = YAML.safe_load(File.read(File.join(__dir__, 'default_module_facts.yml')))
  facts&.each do |name, value|
    add_custom_fact name.to_sym, value
  end
end

Dir["#{__dir__}/support/**/*.rb"].sort.each { |f| require f }
Dir['./spec/support/spec/**/*.rb'].sort.each { |f| require f }
