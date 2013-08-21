# mounttab provider for the Fstab lens (i.e. Linux)
#
# This will be wrapped by the real provider which will load it based on
# OS detection.
#
# Copyright (c) 2012 Dominic Cleal
# Licensed under the Apache License, Version 2.0

require File.dirname(__FILE__) + '/../../augeasproviders'
require File.dirname(__FILE__) + '/../../augeasproviders/mounttab'
require File.dirname(__FILE__) + '/../../augeasproviders/provider'

module AugeasProviders::Mounttab
  class Fstab
    include AugeasProviders::Provider

    attr_reader :resource

    def self.default_file
      '/etc/fstab'
    end

    def self.lens
      'Fstab.lns'
    end

    def self.get_resource(aug, mpath, target)
      entry = {
        :ensure => :present,
        :target => target
      }
      return nil unless entry[:name] = aug.get("#{mpath}/file")
      entry[:device] = aug.get("#{mpath}/spec")
      entry[:fstype] = aug.get("#{mpath}/vfstype")

      options = []
      aug.match("#{mpath}/opt").each do |opath|
        opt = aug.get(opath)
        optv = aug.get("#{opath}/value")
        opt = "#{opt}=#{optv}" if optv
        options << opt
      end
      entry[:options] = options
      entry[:pass] = aug.get("#{mpath}/passno") if aug.match("#{mpath}/passno")
      entry[:dump] = aug.get("#{mpath}/dump") if aug.match("#{mpath}/dump")

      entry
    end

    def self.create(aug, resource)
      aug.set("$target/01/spec", resource[:device])
      aug.set("$target/01/file", resource[:name])
      aug.set("$target/01/vfstype", resource[:fstype])
      insoptions(aug, "$target/01", resource)
      aug.set("$target/01/dump", resource[:dump].to_s)
      aug.set("$target/01/passno", resource[:pass].to_s)
    end

    def self.insoptions(aug, entry, resource)
      # Options are defined as a list property, so they get joined with commas.
      # Since Augeas understands elements, access the original array or string.
      values = resource.original_parameters[:options]

      aug.rm("#{entry}/opt")
      insafter = "vfstype"
      if values and not values.empty?
        [values].flatten.each do |opt|
          optk, optv = opt.split("=", 2)
          aug.insert("#{entry}/#{insafter}", "opt", false)
          aug.set("#{entry}/opt[last()]", optk)
          aug.set("#{entry}/opt[last()]/value", optv) if optv
          insafter = "opt[last()]"
        end
      else
        # Strictly this is optional, but only Augeas > 0.10.0 has a lens that
        # knows this is the case, so always fill it in.
        aug.insert("#{entry}/#{insafter}", "opt", false)
        aug.set("#{entry}/opt", "defaults")
      end
    end

    def self.dump(aug, resource)
      aug.get("$target/*[file = '#{resource[:name]}']/dump")
    end

    def self.set_dump(aug, resource, value)
      # Ensure "defaults" option is always set if dump is being set, as the
      # opts field is optional
      if aug.match("$target/*[file = '#{resource[:name]}']/opt").empty?
        aug.set("$target/*[file = '#{resource[:name]}']/opt", "defaults")
      end

      aug.set("$target/*[file = '#{resource[:name]}']/dump", value.to_s)
    end

    def self.pass(aug, resource)
      aug.get("$target/*[file = '#{resource[:name]}']/passno")
    end

    def self.set_pass(aug, resource, value)
      # Ensure "defaults" option is always set if passno is being set, as the
      # opts field is optional
      if aug.match("$target/*[file = '#{resource[:name]}']/opt").empty?
        aug.set("$target/*[file = '#{resource[:name]}']/opt", "defaults")
      end

      # Ensure dump is always set too
      if aug.match("$target/*[file = '#{resource[:name]}']/dump").empty?
        aug.set("$target/*[file = '#{resource[:name]}']/dump", "0")
      end

      aug.set("$target/*[file = '#{resource[:name]}']/passno", value.to_s)
    end

    def self.atboot(aug, resource)
      resource.should(:atboot)
    end

    def self.set_atboot(aug, resource, value)
      return
    end

    def self.empty_options
      ['', 'defaults']
    end
  end
end
