# Manages variables in simple shell scripts
#
# Copyright (c) 2012 Dominic Cleal
# Licensed under the Apache License, Version 2.0

Puppet::Type.newtype(:shellvar) do
  @doc = "Manages variables in simple shell scripts."

  ensurable do
    desc "Create or remove the shellvar entry"
    defaultvalues
    block if block_given?

    newvalue(:unset) do
      current = self.retrieve
      if current == :absent
        provider.create
      elsif !provider.is_unset?
        provider.unset
      end
    end

    newvalue(:exported) do
      current = self.retrieve
      if current == :absent
        provider.create
      elsif !provider.is_exported?
        provider.export
      end
    end

    def insync?(is)
      return true if should == :unset and is == :present and provider.is_unset?
      return true if should == :exported and is == :present and provider.is_exported?
      return false if should == :present and provider.is_unset?
      return false if should == :present and provider.is_exported?
      super
    end

    def sync
      if should == :present and provider.is_unset?
        provider.ununset
      elsif should == :present and provider.is_exported?
        provider.unexport
      else
        super
      end
    end
  end

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
      if provider.resource[:array_append]
        should_arr = Array(should)

        # Join and split to ensure all elements are parsed
        is_str = is.is_a?(Array) ? is.join(' ') : is
        is_arr = is_str.split(' ')
        (should_arr - is_arr).empty?
      else
        case provider.array_type
        when :string
          is == Array(should.join(' '))
        when :array
          is == should
        end
      end
    end

    def sync
      if provider.resource[:array_append]
        # Merge the two arrays
        is = @resource.property(:value).retrieve

        # Join and split to ensure all elements are parsed
        is_str = is.is_a?(Array) ? is.join(' ') : is
        is_arr = is_str.split(' ')

        provider.value = is_arr | Array(self.should)
      else
        # Use the should array
        provider.value = self.should
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

  newparam(:array_append) do
    desc "Whether to add to existing array values or replace all values."

    newvalues :false, :true

    defaultto :false

    munge do |v|
      case v
      when true, "true", :true
        true
      when false, "false", :false
        false
      end
    end
  end

  newparam(:target) do
    desc "The file in which to store the variable."
  end

  newproperty(:comment) do
    desc "Text to be stored in a comment immediately above the entry.  It will be automatically prepended with the name of the variable in order for the provider to know whether it controls the comment or not."
  end

  newparam(:uncomment) do
    desc "Whether to remove commented value when found."
    
    newvalues :true, :false
    
    defaultto :false

    munge do |v|
      case v
      when true, "true", :true
        :true
      when false, "false", :false
        :false
      end
    end
  end

  autorequire(:file) do
    self[:target]
  end
end
