# Manages settings in OpenSSH's sshd_config file
#
# Copyright (c) 2012 Raphaël Pinson
# Licensed under the Apache License, Version 2.0

Puppet::Type.newtype(:sshd_config) do
  @doc = "Manages settings in an OpenSSH sshd_config file.

The resource name is used for the setting name, but if the `condition` is
given, then the name can be something else and the `key` given as the name
of the setting.

Subsystem entries are not managed by this type. There is a specific `sshd_config_subsystem` type to manage these entries."

  ensurable

  newparam(:name) do
    desc "The name of the setting, or a unique string if `condition` given."
    isnamevar
  end

  newparam(:key) do
    desc "Overrides setting name to prevent resource conflicts if `condition` is
given."
  end

  newproperty(:value, :array_matching => :all) do
    desc "Value to change the setting to. The follow parameters take an array of values:
    
- MACs;
- AcceptEnv;
- AllowGroups;
- AllowUsers;
- DenyGroups;
- DenyUsers.
    
All other parameters take a string. When passing an array to other parameters, only the first value in the array will be considered."
  end

  newparam(:target) do
    desc "The file in which to store the settings, defaults to
`/etc/ssh/sshd_config`."
  end

  newparam(:condition) do
    desc "Match group condition for the entry,
in the format:

    sshd_config { 'PermitRootLogin':
      value     => 'without-password',
      condition => 'Host example.net',
    }

The value can contain multiple conditions, concatenated together with
whitespace.  This is used if the `Match` block has multiple criteria.

    condition => 'Host example.net User root'
      "
  end

  autorequire(:file) do
    self[:target]
  end
end
