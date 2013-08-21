# Manages kernel parameters stored in bootloaders such as GRUB.
#
# Copyright (c) 2012 Dominic Cleal
# Licensed under the Apache License, Version 2.0

Puppet::Type.newtype(:kernel_parameter) do
  @doc = "Manages kernel parameters stored in bootloaders."

  ensurable

  newparam(:name) do
    desc "The parameter name, e.g. 'quiet' or 'vga'."
    isnamevar
  end

  newproperty(:value, :array_matching => :all) do
    desc "Value of the parameter if applicable.  Many parameters are just keywords so this must be left blank, while others (e.g. 'vga') will take a value."
  end

  newparam(:target) do
    desc "The bootloader configuration file, if in a non-default location for the provider."
  end

  newparam(:bootmode) do
    desc "Boot mode(s) to apply the parameter to.  Either 'all' (default) to use the parameter on all boots (normal and recovery mode), 'normal' for just normal boots or 'recovery' for just recovery boots."

    newvalues :all, :normal, :recovery

    defaultto :all
  end

  autorequire(:file) do
    self[:target]
  end
end
