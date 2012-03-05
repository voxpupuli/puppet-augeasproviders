# Alternative Augeas-based providers for Puppet
#
# Copyright (c) 2012 Dominic Cleal
# Licensed under the Apache License, Version 2.0

require 'augeas' if Puppet.features.augeas?

Puppet::Type.type(:host).provide(:augeas) do
  desc "Uses Augeas API to update hosts file"

  def self.file(resource = nil)
    file = nil
    case Facter.value(:operatingsystem)
    when "Solaris"
      file = "/etc/inet/hosts"
    else
      file = "/etc/hosts"
    end
    file = resource[:target] if resource and resource[:target]
    file.chomp("/")
  end

  confine :true   => Puppet.features.augeas? 
  confine :exists => file

  def self.augopen(resource = nil)
    aug = nil
    file = file(resource)
    begin
      aug = Augeas.open(nil, nil, Augeas::NO_MODL_AUTOLOAD)
      aug.transform(
        :lens => "Hosts.lns",
        :name => "Hosts",
        :incl => file
      )
      aug.load!

      if aug.match("/files#{file}").empty?
        message = aug.get("/augeas/files#{file}/error/message")
        fail("Augeas didn't load #{file}: #{message}")
      end
    rescue
      aug.close if aug
      raise
    end
    aug
  end

  def self.instances
    aug = nil
    path = "/files#{file}"
    begin
      resources = []
      aug = augopen
      aug.match("#{path}/*").each do |hpath|
        host = {}
        host[:name] = aug.get("#{hpath}/canonical")
        next unless host[:name]
        host[:ip] = aug.get("#{hpath}/ipaddr")

        aliases = []
        aug.match("#{hpath}/alias").each do |apath|
          aliases << aug.get(apath)
        end
        host[:host_aliases] = aliases

        resources << new(host)
      end
      resources
    ensure
      aug.close if aug
    end
  end

  def exists? 
    aug = nil
    path = "/files#{self.class.file(resource)}"
    begin
      aug = self.class.augopen(resource)
      not aug.match("#{path}/*[canonical = '#{resource[:name]}']").empty?
    ensure
      aug.close if aug
    end
  end

  def create 
    aug = nil
    path = "/files#{self.class.file(resource)}"
    begin
      aug = self.class.augopen(resource)
      aug.set("#{path}/01/ipaddr", resource[:ip])
      aug.set("#{path}/01/canonical", resource[:name])

      if resource[:host_aliases]
        resource[:host_aliases].each do |halias|
          aug.set("#{path}/01/alias[last()+1]", halias)
        end
      end

      if resource[:comment]
        aug.set("#{path}/01/#comment", resource[:comment])
      end

      aug.save!
    ensure
      aug.close if aug
    end
  end

  def destroy
    aug = nil
    path = "/files#{self.class.file(resource)}"
    begin
      aug = self.class.augopen(resource)
      aug.rm("#{path}/*[canonical = '#{resource[:name]}']")
      aug.save!
    ensure
      aug.close if aug
    end
  end

  def target
    self.class.file(resource)
  end

  def ip
    aug = nil
    path = "/files#{self.class.file(resource)}"
    begin
      aug = self.class.augopen(resource)
      aug.get("#{path}/*[canonical = '#{resource[:name]}']/ipaddr")
    ensure
      aug.close if aug
    end
  end

  def ip=(value)
    aug = nil
    path = "/files#{self.class.file(resource)}"
    begin
      aug = self.class.augopen(resource)
      aug.set("#{path}/*[canonical = '#{resource[:name]}']/ipaddr", value)
      aug.save!
    ensure
      aug.close if aug
    end
  end

  def host_aliases
    aug = nil
    path = "/files#{self.class.file(resource)}"
    begin
      aug = self.class.augopen(resource)
      aliases = []
      aug.match("#{path}/*[canonical = '#{resource[:name]}']/alias").each do |apath|
        aliases << aug.get(apath)
      end
      aliases.join(" ")
    ensure
      aug.close if aug
    end
  end

  def host_aliases=(values)
    aug = nil
    path = "/files#{self.class.file(resource)}"
    entry = "#{path}/*[canonical = '#{resource[:name]}']"
    begin
      aug = self.class.augopen(resource)
      aug.rm("#{entry}/alias")

      insafter = "canonical"
      values.split.each do |halias|
        aug.insert("#{entry}/#{insafter}", "alias", false)
        aug.set("#{entry}/alias[last()]", halias)
        insafter = "alias[last()]"
      end

      aug.save!
    ensure
      aug.close if aug
    end
  end

  def comment
    aug = nil
    path = "/files#{self.class.file(resource)}"
    begin
      aug = self.class.augopen(resource)
      aug.get("#{path}/*[canonical = '#{resource[:name]}']/#comment")
    ensure
      aug.close if aug
    end
  end

  def comment=(value)
    aug = nil
    path = "/files#{self.class.file(resource)}"
    begin
      aug = self.class.augopen(resource)
      aug.set("#{path}/*[canonical = '#{resource[:name]}']/#comment", value)
      aug.save!
    ensure
      aug.close if aug
    end
  end
end
