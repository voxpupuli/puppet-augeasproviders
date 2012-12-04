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

    def initialize(provider = nil)
      # Keep reference to things the real provider has access to
      @provider = provider
      @resource = provider.resource if provider and not provider.is_a? Class
    end

    # Utility method available from the provider, used in instances
    def new(*args)
      @provider.send(:new, *args)
    end

    def file(resource = nil)
      file = "/etc/vfstab"
      file = resource[:target] if resource and resource[:target]
      file.chomp("/")
    end

    def augopen(resource = nil)
      AugeasProviders::Provider.augopen("Vfstab.lns", file(resource))
    end

    def instances
      aug = nil
      path = "/files#{file}"
      begin
        resources = []
        aug = augopen
        aug.match("#{path}/*").each do |mpath|
          entry = {:ensure => :present}
          entry[:name] = aug.get("#{mpath}/file")
          next unless entry[:name]
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

          resources << new(entry)
        end
        resources
      ensure
        aug.close if aug
      end
    end

    def exists? 
      aug = nil
      path = "/files#{file(resource)}"
      begin
        aug = augopen(resource)
        not aug.match("#{path}/*[file = '#{resource[:name]}']").empty?
      ensure
        aug.close if aug
      end
    end

    def create 
      aug = nil
      path = "/files#{file(resource)}"
      begin
        aug = augopen(resource)
        aug.set("#{path}/01/spec", resource[:device])
        if resource[:blockdevice] and resource[:blockdevice] != ""
          aug.set("#{path}/01/fsck", resource[:blockdevice])
        end
        aug.set("#{path}/01/file", resource[:name])
        aug.set("#{path}/01/vfstype", resource[:fstype])
        aug.set("#{path}/01/passno", resource[:pass].to_s) unless resource[:pass] == "-"
        aug.set("#{path}/01/atboot", resource[:atboot].to_s)
        insoptions(aug, "#{path}/01", resource)
        augsave!(aug)
      ensure
        aug.close if aug
      end
    end

    def destroy
      aug = nil
      path = "/files#{file(resource)}"
      begin
        aug = augopen(resource)
        aug.rm("#{path}/*[file = '#{resource[:name]}']")
        augsave!(aug)
      ensure
        aug.close if aug
      end
    end

    def target
      file(resource)
    end

    def device
      aug = nil
      path = "/files#{file(resource)}"
      begin
        aug = augopen(resource)
        aug.get("#{path}/*[file = '#{resource[:name]}']/spec")
      ensure
        aug.close if aug
      end
    end

    def device=(value)
      aug = nil
      path = "/files#{file(resource)}"
      begin
        aug = augopen(resource)
        aug.set("#{path}/*[file = '#{resource[:name]}']/spec", value)
        augsave!(aug)
      ensure
        aug.close if aug
      end
    end

    def blockdevice
      aug = nil
      path = "/files#{file(resource)}"
      begin
        aug = augopen(resource)
        aug.get("#{path}/*[file = '#{resource[:name]}']/fsck") or "-"
      ensure
        aug.close if aug
      end
    end

    def blockdevice=(value)
      aug = nil
      path = "/files#{file(resource)}"
      begin
        aug = augopen(resource)
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
      path = "/files#{file(resource)}"
      begin
        aug = augopen(resource)
        aug.get("#{path}/*[file = '#{resource[:name]}']/vfstype")
      ensure
        aug.close if aug
      end
    end

    def fstype=(value)
      aug = nil
      path = "/files#{file(resource)}"
      begin
        aug = augopen(resource)
        aug.set("#{path}/*[file = '#{resource[:name]}']/vfstype", value)
        augsave!(aug)
      ensure
        aug.close if aug
      end
    end

    def pass
      aug = nil
      path = "/files#{file(resource)}"
      begin
        aug = augopen(resource)
        aug.get("#{path}/*[file = '#{resource[:name]}']/passno") or "-"
      ensure
        aug.close if aug
      end
    end

    def pass=(value)
      aug = nil
      path = "/files#{file(resource)}"
      begin
        aug = augopen(resource)
        if value == "-"
          aug.rm("#{path}/*[file = '#{resource[:name]}']/passno")
        else
          if aug.match("#{path}/*[file = '#{resource[:name]}']/passno").empty?
            aug.insert("#{path}/*[file = '#{resource[:name]}']/vfstype", "passno", false)
          end
          aug.set("#{path}/*[file = '#{resource[:name]}']/passno", value.to_s)
        end
        augsave!(aug)
      ensure
        aug.close if aug
      end
    end

    def atboot
      aug = nil
      path = "/files#{file(resource)}"
      begin
        aug = augopen(resource)
        aug.get("#{path}/*[file = '#{resource[:name]}']/atboot")
      ensure
        aug.close if aug
      end
    end

    def atboot=(value)
      aug = nil
      path = "/files#{file(resource)}"
      begin
        aug = augopen(resource)
        aug.set("#{path}/*[file = '#{resource[:name]}']/atboot", value.to_s)
        augsave!(aug)
      ensure
        aug.close if aug
      end
      return
    end

    def options
      aug = nil
      path = "/files#{file(resource)}"
      begin
        aug = augopen(resource)
        opts = []
        aug.match("#{path}/*[file = '#{resource[:name]}']/opt").each do |opath|
          opt = aug.get(opath)
          optv = aug.get("#{opath}/value")
          opt = "#{opt}=#{optv}" if optv
          opts << opt
        end
        opts = opts.join(",")

        # [] and ["-"] are synonyms, so return what the user requested if
        # the current value is one of these to avoid changes
        empties = ["", "-"]
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

    def options=(values)
      aug = nil
      path = "/files#{file(resource)}"
      entry = "#{path}/*[file = '#{resource[:name]}']"
      begin
        aug = augopen(resource)
        insoptions(aug, entry, resource)
        augsave!(aug)
      ensure
        aug.close if aug
      end
    end

    def dump
      resource.should(:dump)
    end
  end
end
