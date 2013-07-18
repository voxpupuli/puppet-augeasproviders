# Manages variables in simple shell scripts
#
# Copyright (c) 2012 Dominic Cleal
# Licensed under the Apache License, Version 2.0

Puppet::Type.newtype(:shellvar) do
  @doc = "Manages variables in simple shell scripts."

  ensurable

  newparam(:variable) do
    desc "The name of the variable, e.g. OPTIONS"
    isnamevar
  end

  newproperty(:value, :array_matching => :all) do
    desc "Value to change the variable to."

    munge do |v|
      v.to_s
    end

    def insync?(is)
      case provider.array_type
      when :string
        is == Array(should.join(' '))
      when :array
        is == should
      end
    end
  end

  newparam(:quoted) do
    desc "Quoting method to use, defaults to `auto`.

* `auto` will quote only if necessary, leaving existing quotes as-is
* `double` and `single` will always quotes
* `none` will remove quotes, which may result in save failures"

    newvalues :auto, :double, :single, :none, :false, :true

    defaultto :auto

    munge do |v|
      case v
      when true, "true", :true
        :auto
      when false, "false", :false
        :none
      else
        v.to_sym
      end
    end
  end

  newparam(:array_type) do
    desc "Type of array mapping to use, defaults to `auto`.

* `auto` will detect the current type, and default to `string`
* `string` will render the array as a string and use space-separated values
* `array` will render the array as a shell array"

    newvalues :auto, :string, :array

    defaultto :auto
  end

  newparam(:target) do
    desc "The file in which to store the variable."
  end

  newproperty(:comment) do
    desc "Text to be stored in a comment immediately above the entry.  It will be automatically prepended with the name of the variable in order for the provider to know whether it controls the comment or not."
  end

  autorequire(:file) do
    self[:target]
  end
end
