# GRUB 2 support for kernel parameters, edits /etc/default/grub
#
# Copyright (c) 2012 Dominic Cleal
# Licensed under the Apache License, Version 2.0

require File.dirname(__FILE__) + '/../../../augeasproviders/provider'

Puppet::Type.type(:kernel_parameter).provide(:grub2) do
  desc "Uses Augeas API to update kernel parameters in GRUB2's /etc/default/grub"

  include AugeasProviders::Provider

  default_file { '/etc/default/grub' }

  lens { 'Shellvars_list.lns' }

  resource_path do |resource|
    "$target/#{section(resource)}/value[.=~regexp('^#{resource[:name]}(=.*)?$')]"
  end

  def self.mkconfig_path
    which("grub2-mkconfig") or which("grub-mkconfig") or '/usr/sbin/grub-mkconfig'
  end

  confine :feature => :augeas
  commands :mkconfig => mkconfig_path

  def self.instances
    augopen do |aug|
      resources = []

      # Params are nicely separated, but no recovery-only setting (hard-coded)
      sections = { 'all'    => "GRUB_CMDLINE_LINUX",
                   'normal' => "GRUB_CMDLINE_LINUX_DEFAULT" }
      sections.keys.sort.each do |bootmode|
        key = sections[bootmode]
        # Get all unique param names
        params = aug.match("$target/#{key}/value").map { |pp|
          aug.get(pp).split("=")[0]
        }.uniq

        # Find all values for each param name
        params.each do |param|
          vals = aug.match("$target/#{key}/value[.=~regexp('^#{param}(=.*)?$')]").map {|vp|
            aug.get(vp).split("=", 2)[1]
          }
          vals = vals[0] if vals.size == 1

          param = {:ensure => :present, :name => param, :value => vals, :bootmode => bootmode}
          resources << new(param)
        end
      end
      resources
    end
  end

  def self.section(resource)
    case resource[:bootmode].to_s
    when "normal"
      "GRUB_CMDLINE_LINUX_DEFAULT"
    when "all"
      "GRUB_CMDLINE_LINUX"
    else
      fail("Unsupported bootmode for #{self.class.to_s} provider")
    end
  end

  def create
    self.value=(resource[:value])
  end

  def value
    augopen do |aug|
      aug.match('$resource').map {|vp|
        aug.get(vp).split("=", 2)[1]
      }
    end
  end

  def value=(newval)
    augopen! do |aug|
      if newval && !newval.empty?
        vals = newval.clone
      else
        # If no value (e.g. "quiet") then clear the value from the first and
        # delete the rest
        vals = nil
        aug.set("#{resource_path}[1]", resource[:name])
        aug.rm("#{resource_path}[position() > 1]")
      end

      # Set any existing parameters with this name, remove excess ones
      if vals
        aug.match('$resource').each do |ppath|
          val = vals.shift
          if val.nil?
            aug.rm(ppath)
          else
            aug.set(ppath, "#{resource[:name]}=#{val}")
          end
        end
      end

      # Add new parameters where there are more values than existing params
      if vals && !vals.empty?
        vals.each do |val|
          aug.set("$target/#{self.class.section(resource)}/value[last()+1]", "#{resource[:name]}=#{val}")
        end
      end
    end
  end

  def flush
    cfg = nil
    ["/boot/grub/grub.cfg", "/boot/grub2/grub.cfg"].each {|c|
      cfg = c if FileTest.file? c
    }
    fail("Cannot find grub.cfg location to use with grub-mkconfig") unless cfg
    
    super
    mkconfig "-o", cfg
  end
end
