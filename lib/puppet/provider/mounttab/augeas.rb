# Alternative Augeas-based provider for mounttab, distributed in
# puppetlabs-mount_providers.
#
# This is a wrapper around different implementations, which lives in the
# AugeasProviders namespace.  The idea is to use a single provider called
# "augeas" so site-wide defaults can be set rather than forcing the user to
# set the provider based on OS upfront.  The equivalent of confining the
# provider based on OS is instead done here.
#
# Copyright (c) 2012 Dominic Cleal
# Licensed under the Apache License, Version 2.0

require File.dirname(__FILE__) + '/../../../augeasproviders/provider'
require File.dirname(__FILE__) + '/../../../augeasproviders/mounttab/fstab'
require File.dirname(__FILE__) + '/../../../augeasproviders/mounttab/vfstab'

Puppet::Type.type(:mounttab).provide(:augeas) do
  desc "Uses Augeas API to update the /etc/(v)fstab file"

  def self.osimpl
    os = Facter.value(:osfamily) or Facter.value(:operatingsystem)
    case os
    when "Solaris"
      AugeasProviders::Mounttab::Vfstab
    else
      AugeasProviders::Mounttab::Fstab
    end
  end

  confine :feature => :augeas
  confine :exists => osimpl.new.file

  def self.instances
    osimpl.new(self).instances
  end

  def method_missing(method, *args)
    self.class.osimpl.new(self).send(method, *args)
  end

  def respond_to?(method)
    self.class.osimpl.new(self).respond_to? method
  end
end
