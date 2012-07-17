# Manages settings in OpenSSH's sshd_config file
#
# Copyright (c) 2012 Raphaël Pinson
# Licensed under the Apache License, Version 2.0

Puppet::Type.newtype(:sshd_config_subsystem) do
  @doc = "Manages Subsystem settings in an OpenSSH sshd_config file."

  ensurable

  newparam(:name) do
    desc "The name of the setting, or a unique string if `condition` given."
    isnamevar
  end

  newproperty(:value) do
    desc "Value to change the setting to."
  end

  newparam(:target) do
    desc "The file in which to store the settings, defaults to
      `/etc/ssh/sshd_config`."
  end
end
