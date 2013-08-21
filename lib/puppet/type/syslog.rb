# Manages settings in syslog.conf file
#
# Copyright (c) 2012 Raphaël Pinson
# Licensed under the Apache License, Version 2.0

Puppet::Type.newtype(:syslog) do
  @doc = "Manages settings in syslog.conf."

  ensurable

  def munge_boolean(value)
    case value
    when true, "true", :true
      :true
    when false, "false", :false
      :false
    else
      fail("munge_boolean only takes booleans")
    end
  end

  newparam(:name) do
    desc "The name of the resource."
    isnamevar
  end

  newparam(:facility) do
    desc "The syslog facility for the selector."
  end

  newparam(:level) do
    desc "The syslog level for the selector."
  end

  newparam(:action_type) do
    desc "The type of action: file, hostname, user or program."
  end

  newparam(:action) do
    desc "The action for the entry."
  end

  newproperty(:no_sync, :boolean => true) do
    desc "Whether to omit syncing the file after every logging, ony when action_type is file."

    newvalue(:true)
    newvalue(:false)

    munge do |value|
      @resource.munge_boolean(value)
    end
  end

  newparam(:target) do
    desc "The file in which to store the settings, defaults to
      `/etc/syslog.conf`."
  end

  newparam(:lens) do
    desc "The augeas lens used to parse the file"
  end

  autorequire(:file) do
    self[:target]
  end
end
