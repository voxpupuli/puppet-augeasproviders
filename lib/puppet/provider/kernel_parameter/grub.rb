# GRUB legacy / 0.9x support for kernel parameters
#
# Copyright (c) 2012 Dominic Cleal
# Licensed under the Apache License, Version 2.0

require File.dirname(__FILE__) + '/../../../augeasproviders/provider'

Puppet::Type.type(:kernel_parameter).provide(:grub) do
  desc "Uses Augeas API to update kernel parameters in GRUB's menu.lst"

  include AugeasProviders::Provider

  default_file do
    FileTest.exist?("/boot/efi/EFI/redhat/grub.conf") ? "/boot/efi/EFI/redhat/grub.conf" : "/boot/grub/menu.lst"
  end

  lens { 'Grub.lns' }

  confine :feature => :augeas
  confine :exists => target

  # Useful XPath to match only recovery entries
  MODE_RECOVERY = "(kernel/S or kernel/1 or kernel/single or .=~regexp('.*\((single-user|recovery) mode\).*'))"
  MODE_NOT_RECOVERY = "(count(kernel/S)=0 and count(kernel/1)=0 and count(kernel/single)=0 and .!~regexp('.*\((single-user|recovery) mode\).*'))"

  def title_filter
    case resource[:bootmode]
    when :recovery
      "[#{MODE_RECOVERY}]"
    when :normal
      "[#{MODE_NOT_RECOVERY}]"
    else
      ""
    end
  end

  def self.instances
    augopen do |aug|
      resources = []
      # Get all unique parameter names
      params = aug.match("$target/title/kernel/*").map {|pp| pp.split("/")[-1].split("[")[0] }.uniq

      params.each do |pp|
        # Then retrieve all unique values as string (1) or array
        vals = aug.match("$target/title/kernel/#{pp}").map {|vp| aug.get(vp) }.uniq
        vals = vals[0] if vals.size == 1

        param = {:ensure => :present, :name => pp, :value => vals}

        # Check if this param is used in recovery entries too, irrespective of value
        is_recv = !aug.match("$target/title[#{MODE_RECOVERY} and kernel/#{pp}]").empty?
        is_norm = !aug.match("$target/title[#{MODE_NOT_RECOVERY} and kernel/#{pp}]").empty?
        if is_recv && is_norm
          param[:bootmode] = :all
        elsif is_recv
          param[:bootmode] = :recovery
        else
          param[:bootmode] = :normal
        end

        resources << new(param)
      end
      resources
    end
  end

  def exists?
    augopen do |aug|
      if resource[:ensure] == :absent
        # Existence is specific - if it exists on any kernel, so it gets destroyed
        !aug.match("$target/title#{title_filter}/kernel/#{resource[:name]}").empty?
      else  # if present
        # Existence is specific - it must exist on all kernels, or we'll fix it
        !aug.match("$target/title#{title_filter}/kernel").find do |kpath|
          aug.match("#{kpath}/#{resource[:name]}").empty?
        end
      end
    end
  end

  def create
    self.value=(resource[:value])
  end

  def destroy
    augopen! do |aug|
      aug.rm("$target/title#{title_filter}/kernel/#{resource[:name]}")
    end
  end

  def value
    augopen do |aug|
      aug.match("$target/title#{title_filter}/kernel/#{resource[:name]}").map {|p| aug.get(p) }.uniq
    end
  end

  def value=(newval)
    augopen! do |aug|
      aug.match("$target/title#{title_filter}/kernel").each do |kpath|
        if newval && !newval.empty?
          vals = newval.clone
        else
          # If no value (e.g. "quiet") then clear the first and delete the rest
          vals = nil
          aug.clear("#{kpath}/#{resource[:name]}[1]")
          aug.rm("#{kpath}/#{resource[:name]}[position() > 1]")
        end

        # Set any existing parameters with this name, remove excess ones
        if vals
          aug.match("#{kpath}/#{resource[:name]}").each do |ppath|
            val = vals.shift
            if val.nil?
              aug.rm(ppath)
            else
              aug.set(ppath, val)
            end
          end
        end

        # Add new parameters where there are more values than existing params
        if vals && !vals.empty?
          vals.each do |val|
            aug.set("#{kpath}/#{resource[:name]}[last()+1]", val)
          end
        end
      end
    end
  end
end
