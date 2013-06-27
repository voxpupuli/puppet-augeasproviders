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

  include AugeasProviders::Provider

  default_file do
    osimpl.default_file
  end

  lens do
    osimpl.lens
  end

  confine :feature => :augeas
  confine :exists => target
  defaultfor :feature => :augeas

  def self.instances
    aug = nil
    file = target
    path = "/files#{file}"
    begin
      resources = []
      aug = augopen
      aug.match("#{path}/*").each do |mpath|
        entry = osimpl.get_resource(aug, mpath, file)
        resources << new(entry) unless entry.nil?
      end
      resources
    ensure
      aug.close if aug
    end
  end

  def exists? 
    aug = nil
    path = "/files#{self.class.target(resource)}"
    begin
      aug = self.class.augopen(resource)
      not aug.match("#{path}/*[file = '#{resource[:name]}']").empty?
    ensure
      aug.close if aug
    end
  end

  def create 
    aug = nil
    path = "/files#{self.class.target(resource)}"
    begin
      aug = self.class.augopen(resource)
      self.class.osimpl.create(aug, path, resource)
      augsave!(aug)
    ensure
      aug.close if aug
    end
  end

  def destroy
    aug = nil
    path = "/files#{self.class.target(resource)}"
    begin
      aug = self.class.augopen(resource)
      aug.rm("#{path}/*[file = '#{resource[:name]}']")
      augsave!(aug)
    ensure
      aug.close if aug
    end
  end

  def target
    self.class.target(resource)
  end

  def device
    aug = nil
    path = "/files#{self.class.target(resource)}"
    begin
      aug = self.class.augopen(resource)
      aug.get("#{path}/*[file = '#{resource[:name]}']/spec")
    ensure
      aug.close if aug
    end
  end

  def device=(value)
    aug = nil
    path = "/files#{self.class.target(resource)}"
    begin
      aug = self.class.augopen(resource)
      aug.set("#{path}/*[file = '#{resource[:name]}']/spec", value)
      augsave!(aug)
    ensure
      aug.close if aug
    end
  end

  def blockdevice
    aug = nil
    path = "/files#{self.class.target(resource)}"
    begin
      aug = self.class.augopen(resource)
      aug.get("#{path}/*[file = '#{resource[:name]}']/fsck") or "-"
    ensure
      aug.close if aug
    end
  end

  def blockdevice=(value)
    aug = nil
    path = "/files#{self.class.target(resource)}"
    begin
      aug = self.class.augopen(resource)
      if value == "-"
        aug.rm("#{path}/*[file = '#{resource[:name]}']/fsck")
      else
        if aug.match("#{path}/*[file = '#{resource[:name]}']/fsck").empty?
          aug.insert("#{path}/*[file = '#{resource[:name]}']/spec", "fsck", false)
        end
        aug.set("#{path}/*[file = '#{resource[:name]}']/fsck", value.to_s)
      end
      augsave!(aug)
    ensure
      aug.close if aug
    end
  end

  def fstype
    aug = nil
    path = "/files#{self.class.target(resource)}"
    begin
      aug = self.class.augopen(resource)
      aug.get("#{path}/*[file = '#{resource[:name]}']/vfstype")
    ensure
      aug.close if aug
    end
  end

  def fstype=(value)
    aug = nil
    path = "/files#{self.class.target(resource)}"
    begin
      aug = self.class.augopen(resource)
      aug.set("#{path}/*[file = '#{resource[:name]}']/vfstype", value)
      augsave!(aug)
    ensure
      aug.close if aug
    end
  end

  def options
    aug = nil
    path = "/files#{self.class.target(resource)}"
    begin
      aug = self.class.augopen(resource)
      opts = []
      aug.match("#{path}/*[file = '#{resource[:name]}']/opt").each do |opath|
        opt = aug.get(opath)
        optv = aug.get("#{opath}/value")
        opt = "#{opt}=#{optv}" if optv
        opts << opt
      end
      opts = opts.join(",")

      # [] and ["defaults"] are synonyms, so return what the user requested if
      # the current value is one of these to avoid changes
      empties = self.class.osimpl.empty_options
      if empties.include?(opts) and empties.include?(resource.should(:options))
        resource.should(:options)
      else
        opts
      end
    ensure
      aug.close if aug
    end
  end

  def insoptions(aug, entry, resource)
    self.class.osimpl.insoptions(aug, entry, resource)
  end

  def options=(values)
    aug = nil
    path = "/files#{self.class.target(resource)}"
    entry = "#{path}/*[file = '#{resource[:name]}']"
    begin
      aug = self.class.augopen(resource)
      insoptions(aug, entry, resource)
      augsave!(aug)
    ensure
      aug.close if aug
    end
  end

  def dump
    aug = nil
    path = "/files#{self.class.target(resource)}"
    begin
      aug = self.class.augopen(resource)
      self.class.osimpl.dump(aug, path, resource)
    ensure
      aug.close if aug
    end
  end

  def dump=(value)
    aug = nil
    path = "/files#{self.class.target(resource)}"
    begin
      aug = self.class.augopen(resource)
      self.class.osimpl.set_dump(aug, path, resource, value)
      augsave!(aug)
    ensure
      aug.close if aug
    end
  end

  def pass
    aug = nil
    path = "/files#{self.class.target(resource)}"
    begin
      aug = self.class.augopen(resource)
      self.class.osimpl.pass(aug, path, resource)
    ensure
      aug.close if aug
    end
  end

  def pass=(value)
    aug = nil
    path = "/files#{self.class.target(resource)}"
    begin
      aug = self.class.augopen(resource)
      self.class.osimpl.set_pass(aug, path, resource, value)
      augsave!(aug)
    ensure
      aug.close if aug
    end
  end

  def atboot
    aug = nil
    path = "/files#{self.class.target(resource)}"
    begin
      aug = self.class.augopen(resource)
      self.class.osimpl.atboot(aug, path, resource)
    ensure
      aug.close if aug
    end
  end

  def atboot=(value)
    aug = nil
    path = "/files#{self.class.target(resource)}"
    begin
      aug = self.class.augopen(resource)
      self.class.osimpl.set_atboot(aug, path, resource, value)
      augsave!(aug)
    ensure
      aug.close if aug
    end
  end
end
