# Manages settings in PAM service files
#
# Copyright (c) 2012 Greg Swift
# Licensed under the Apache License, Version 2.0

require File.dirname(__FILE__) + '/../../augeasproviders/type'

Puppet::Type.newtype(:pam) do
  @doc = "Manages settings in an PAM service files.

The resource name is a descriptive string only due to the non-uniqueness of any single paramter."

  extend AugeasProviders::Type

  positionable

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
      desc "The name of the resource, has no bearing on anything"
      isnamevar
  end

  newparam(:service) do
    desc "The PAM service this entry will be placed in.  Typically this is the same as the
filename under /etc/pam.d"
  end

  newparam(:type) do
    desc "The PAM service type of the setting: account, auth, password, session."
    newvalues(:account, :auth, :password, :session)
  end

  newparam(:module) do
    desc "The name of the specific PAM module to load."
  end

  newproperty(:optional, :boolean => true) do
    desc "Whether failure to load the module will break things"

    newvalue(:true)
    newvalue(:false)

    munge do |value|
      @resource.munge_boolean(value)
    end
  end

  newproperty(:arguments, :array_matching => :all) do
    desc "Arguments to assign for the module."
    defaultto { [] }
  end

  newproperty(:control) do
    desc "Simple or complex definition of the module's behavior on failure."
  end

  newparam(:control_is_param, :boolean => true) do
    desc "Whether `control` should be considered a parameter or a property."

    newvalues :false, :true
    defaultto :false

    munge do |value|
      @resource.munge_boolean(value)
    end
  end

  newparam(:position) do
    desc "A three part text field that providers the placement position of an entry.

The field consists of `placement identifier value`

Placement can be either `before` or `after`
Identifier can be either `first`, `last`, `module`, or an Augeas xpath
Value is matched as follows:
  With `first` and `last` match `value` to the `control` field, can be blank for absolute positioning.
  With `module` matches the `module` field of the associated line, can not be blank.
  With an Augeas xpath this field will be ignored, and should be blank.
"
    defaultto('before last')
    validate do |value|
      placement, identifier, val = value.split(/ /)
      unless ['before', 'after'].include? placement
        raise ArgumentError, "%s is not a valid placement in position" % placement
      end
# Don't do validation of the second field because we are supporting xpath
# and thats hard to validate
#      unless ['first', 'last', 'module'].include? identifier or identifier =~ //
#        raise ArgumentError, "%s is not a valid identifier in position" % indentifier
#      end
      if val.nil? and identifier == 'module'
        raise ArgumentError, "Value must be set if you are matching on module"
      end
    end
  end

  newparam(:target) do
    desc "The file in which to store the settings, defaults to `/etc/pam.d/{service}`."
  end

end
