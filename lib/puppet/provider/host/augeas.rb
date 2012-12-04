# Alternative Augeas-based provider for host type (Puppet builtin)
#
# Copyright (c) 2012 Dominic Cleal
# Licensed under the Apache License, Version 2.0

require File.dirname(__FILE__) + '/../../../augeasproviders/provider'

Puppet::Type.type(:host).provide(:augeas) do
  desc "Uses Augeas API to update hosts file"

  include AugeasProviders::Provider

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

  confine :feature => :augeas
  confine :exists => file

  def self.augopen(resource = nil)
    AugeasProviders::Provider.augopen("Hosts.lns", file(resource))
  end

  def self.instances
    aug = nil
    path = "/files#{file}"
    begin
      resources = []
      aug = augopen
      aug.match("#{path}/*").each do |hpath|
        host = {:ensure => :present}
        host[:name] = aug.get("#{hpath}/canonical")
        next unless host[:name]
        host[:ip] = aug.get("#{hpath}/ipaddr")

        aliases = []
        aug.match("#{hpath}/alias").each do |apath|
          aliases << aug.get(apath)
        end
        host[:host_aliases] = aliases unless aliases.empty?

        comment = aug.get("#{hpath}/#comment")
        host[:comment] = comment if comment

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
        values = resource[:host_aliases]
        values = values.split unless values.is_a? Array
        values.each do |halias|
          aug.set("#{path}/01/alias[last()+1]", halias)
        end
      end

      # comment property only available in Puppet 2.7+
      if Puppet::Type.type(:host).validattr? :comment and resource[:comment]
        aug.set("#{path}/01/#comment", resource[:comment])
      end

      augsave!(aug)
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
      augsave!(aug)
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
      augsave!(aug)
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
      if resource.should(:host_aliases).is_a? Array
        aliases
      else
        aliases.join(" ")
      end
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
      values = values.split unless values.is_a? Array
      values.each do |halias|
        aug.insert("#{entry}/#{insafter}", "alias", false)
        aug.set("#{entry}/alias[last()]", halias)
        insafter = "alias[last()]"
      end

      augsave!(aug)
    ensure
      aug.close if aug
    end
  end

  def comment
    aug = nil
    path = "/files#{self.class.file(resource)}"
    begin
      aug = self.class.augopen(resource)
      aug.get("#{path}/*[canonical = '#{resource[:name]}']/#comment") || ""
    ensure
      aug.close if aug
    end
  end

  def comment=(value)
    aug = nil
    path = "/files#{self.class.file(resource)}"
    begin
      aug = self.class.augopen(resource)
      if value.empty?
        aug.rm("#{path}/*[canonical = '#{resource[:name]}']/#comment")
      else
        aug.set("#{path}/*[canonical = '#{resource[:name]}']/#comment", value)
      end
      augsave!(aug)
    ensure
      aug.close if aug
    end
  end
end
