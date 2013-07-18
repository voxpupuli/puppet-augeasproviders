# Manages SetEnv entries in a Apache config
#
# Copyright (c) 2013 Endre Karlson
# Licensed under the Apache License, Version 2.0

require "puppet"


module Puppet
  Puppet::Type.newtype(:apache_setenv) do
    @doc = "Manages SetEnv entries in a Apache config"

    ensurable

    newparam(:name) do
      desc "The variable name to set"
      isnamevar
    end

    newproperty(:value) do
      desc "The value to set it to"
    end

    newparam(:target) do
      desc "The config file to use"
    end

    autorequire(:file) do
      self[:target]
    end
  end
end
