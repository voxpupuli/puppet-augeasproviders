# Manages Apache directives
#
# Copyright (c) 2013 Raphaël Pinson
# Licensed under the Apache License, Version 2.0

require File.dirname(__FILE__) + '/../../augeasproviders/type'

Puppet::Type.newtype(:apache_directive) do
  @doc = 'Manages Apache directives'

  extend AugeasProviders::Type

  ensurable

  newparam(:name) do
    desc 'The directive name'
    isnamevar
  end

  newparam(:context) do
    desc 'The path where the directive is located. Expressed as an Augeas path expression.'
    defaultto ''
  end

  newproperty(:args, :array_matching => :all) do
    desc 'An array of directive arguments'
  end

  newparam(:args_params) do
    desc 'How many arguments are to be used as params'
    defaultto 0

    validate do |value|
      raise "Wrong args_params value '#{value}'" unless value.to_i >= 0
    end
  end

  newparam(:target) do
    desc 'The config file to use'
  end
end
