# Manages command entries in nrpe.cfg
#
# Copyright (c) 2012 Christian Kaenzig
# Licensed under the Apache License, Version 2.0

Puppet::Type.newtype(:nrpe_command) do
  @doc = "Manages commands in /etc/nagios/nrpe.cfg."

  ensurable

  newparam(:name) do
    desc "The name of the command, e.g. check_my_stuff"
    isnamevar
  end

  newproperty(:command) do
    desc "Check command to run on the system, with arguments"
  end

  newparam(:target) do
    desc "The file in which to store the command, defaults to
      `/etc/nagios/nrpe.cfg`."
  end

  autorequire(:file) do
    self[:target]
  end
end
