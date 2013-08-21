# mounttab provider for the Vfstab lens for Solaris
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
  class Vfstab
    include AugeasProviders::Provider

    attr_reader :resource

    def self.default_file
      '/etc/vfstab'
    end

    def self.lens
      'Vfstab.lns'
    end

    def self.get_resource(aug, mpath, target)
      entry = {
        :ensure => :present,
        :target => target
      }
      return nil unless entry[:name] = aug.get("#{mpath}/file")
      entry[:device] = aug.get("#{mpath}/spec")
      entry[:fstype] = aug.get("#{mpath}/vfstype")
      entry[:blockdevice] = (aug.get("#{mpath}/fsck") or "-")
      entry[:pass] = (aug.get("#{mpath}/passno") or "-")
      entry[:atboot] = aug.get("#{mpath}/atboot")

      options = []
      aug.match("#{mpath}/opt").each do |opath|
        opt = aug.get(opath)
        optv = aug.get("#{opath}/value")
        opt = "#{opt}=#{optv}" if optv
        options << opt
      end
      entry[:options] = if options.empty?
        "-"
      else
        options
      end

      entry
    end

    def self.create(aug, resource)
      aug.set("$target/01/spec", resource[:device])
      if resource[:blockdevice] and resource[:blockdevice] != ""
        aug.set("$target/01/fsck", resource[:blockdevice])
      end
      aug.set("$target/01/file", resource[:name])
      aug.set("$target/01/vfstype", resource[:fstype])
      aug.set("$target/01/passno", resource[:pass].to_s) unless resource[:pass] == "-"
      aug.set("$target/01/atboot", resource[:atboot].to_s)
      insoptions(aug, "$target/01", resource)
    end

    def target
      file(resource)
    end

    def self.insoptions(aug, entry, resource)
      # Options are defined as a list property, so they get joined with commas.
      # Since Augeas understands elements, access the original array or string.
      values = resource.original_parameters[:options]

      aug.rm("#{entry}/opt")
      if values and not values.empty?
        [values].flatten.each do |opt|
          optk, optv = opt.split("=", 2)
          aug.set("#{entry}/opt[last()+1]", optk)
          aug.set("#{entry}/opt[last()]/value", optv) if optv
        end
      end
    end

    def self.dump(aug, resource)
      resource.should(:dump)
    end

    def self.set_dump(aug, resource, value)
      return
    end

    def self.pass(aug, resource)
      aug.get("$target/*[file = '#{resource[:name]}']/passno") or "-"
    end

    def self.set_pass(aug, resource, value)
      if value == "-"
        aug.rm("$target/*[file = '#{resource[:name]}']/passno")
      else
        if aug.match("$target/*[file = '#{resource[:name]}']/passno").empty?
          aug.insert("$target/*[file = '#{resource[:name]}']/vfstype", "passno", false)
        end
        aug.set("$target/*[file = '#{resource[:name]}']/passno", value.to_s)
      end
    end

    def self.atboot(aug, resource)
      aug.get("$target/*[file = '#{resource[:name]}']/atboot")
    end

    def self.set_atboot(aug, resource, value)
      aug.set("$target/*[file = '#{resource[:name]}']/atboot", value.to_s)
    end

    def self.empty_options
      ['', '-']
    end
  end
end
