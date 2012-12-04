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

    def initialize(provider = nil)
      # Keep reference to things the real provider has access to
      @provider = provider
      @resource = provider.resource if provider and not provider.is_a? Class
    end

    # Utility method available from the provider, used in instances
    def new(*args)
      @provider.send(:new, *args)
    end

    def file
      file = "/etc/fstab"
      file = resource[:target] if resource and resource[:target]
      file.chomp("/")
    end

    def augopen
      AugeasProviders::Provider.augopen("Fstab.lns", file)
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

          resources << new(entry)
        end
        resources
      ensure
        aug.close if aug
      end
    end

    def exists? 
      aug = nil
      path = "/files#{file}"
      begin
        aug = augopen
        not aug.match("#{path}/*[file = '#{resource[:name]}']").empty?
      ensure
        aug.close if aug
      end
    end

    def create 
      aug = nil
      path = "/files#{file}"
      begin
        aug = augopen
        aug.set("#{path}/01/spec", resource[:device])
        aug.set("#{path}/01/file", resource[:name])
        aug.set("#{path}/01/vfstype", resource[:fstype])
        insoptions(aug, "#{path}/01", resource)
        aug.set("#{path}/01/dump", resource[:dump].to_s)
        aug.set("#{path}/01/passno", resource[:pass].to_s)
        augsave!(aug)
      ensure
        aug.close if aug
      end
    end

    def destroy
      aug = nil
      path = "/files#{file}"
      begin
        aug = augopen
        aug.rm("#{path}/*[file = '#{resource[:name]}']")
        augsave!(aug)
      ensure
        aug.close if aug
      end
    end

    def target
      file
    end

    def device
      aug = nil
      path = "/files#{file}"
      begin
        aug = augopen
        aug.get("#{path}/*[file = '#{resource[:name]}']/spec")
      ensure
        aug.close if aug
      end
    end

    def device=(value)
      aug = nil
      path = "/files#{file}"
      begin
        aug = augopen
        aug.set("#{path}/*[file = '#{resource[:name]}']/spec", value)
        augsave!(aug)
      ensure
        aug.close if aug
      end
    end

    def fstype
      aug = nil
      path = "/files#{file}"
      begin
        aug = augopen
        aug.get("#{path}/*[file = '#{resource[:name]}']/vfstype")
      ensure
        aug.close if aug
      end
    end

    def fstype=(value)
      aug = nil
      path = "/files#{file}"
      begin
        aug = augopen
        aug.set("#{path}/*[file = '#{resource[:name]}']/vfstype", value)
        augsave!(aug)
      ensure
        aug.close if aug
      end
    end

    def options
      aug = nil
      path = "/files#{file}"
      begin
        aug = augopen
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
        empties = ["", "defaults"]
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

    def options=(values)
      aug = nil
      path = "/files#{file}"
      entry = "#{path}/*[file = '#{resource[:name]}']"
      begin
        aug = augopen
        insoptions(aug, entry, resource)
        augsave!(aug)
      ensure
        aug.close if aug
      end
    end

    def dump
      aug = nil
      path = "/files#{file}"
      begin
        aug = augopen
        aug.get("#{path}/*[file = '#{resource[:name]}']/dump")
      ensure
        aug.close if aug
      end
    end

    def dump=(value)
      aug = nil
      path = "/files#{file}"
      begin
        aug = augopen

        # Ensure "defaults" option is always set if dump is being set, as the
        # opts field is optional
        if aug.match("#{path}/*[file = '#{resource[:name]}']/opt").empty?
          aug.set("#{path}/*[file = '#{resource[:name]}']/opt", "defaults")
        end

        aug.set("#{path}/*[file = '#{resource[:name]}']/dump", value.to_s)
        augsave!(aug)
      ensure
        aug.close if aug
      end
    end

    def pass
      aug = nil
      path = "/files#{file}"
      begin
        aug = augopen
        aug.get("#{path}/*[file = '#{resource[:name]}']/passno")
      ensure
        aug.close if aug
      end
    end

    def pass=(value)
      aug = nil
      path = "/files#{file}"
      begin
        aug = augopen

        # Ensure "defaults" option is always set if passno is being set, as the
        # opts field is optional
        if aug.match("#{path}/*[file = '#{resource[:name]}']/opt").empty?
          aug.set("#{path}/*[file = '#{resource[:name]}']/opt", "defaults")
        end

        # Ensure dump is always set too
        if aug.match("#{path}/*[file = '#{resource[:name]}']/dump").empty?
          aug.set("#{path}/*[file = '#{resource[:name]}']/dump", "0")
        end

        aug.set("#{path}/*[file = '#{resource[:name]}']/passno", value.to_s)
        augsave!(aug)
      ensure
        aug.close if aug
      end
    end

    def atboot
      resource.should(:atboot)
    end

    def atboot=(value)
      return
    end
  end
end
