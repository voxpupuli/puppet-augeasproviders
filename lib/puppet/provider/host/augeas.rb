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

  def self.augopen(target)
    AugeasProviders::Provider.augopen("Hosts.lns", target)
  end

  def self.get_resource(aug, hpath, target)
    host = {
      :ensure => :present,
      :target => target
    }
    return nil unless host[:name] = aug.get("#{hpath}/canonical")
    host[:ip] = aug.get("#{hpath}/ipaddr")

    aliases = aug.match("#{hpath}/alias").map { |apath| aug.get(apath) }
    host[:host_aliases] = aliases unless aliases.empty?

    comment = aug.get("#{hpath}/#comment")
    host[:comment] = comment if comment

    host
  end

  def self.get_resources(target)
    aug = nil
    path = "/files#{target}"
    begin
      aug = augopen(target)
      resources = aug.match("#{path}/*").map {
        |p| get_resource(aug, p, target)
      }.compact.map { |r| new(r) }
      resources
    ensure
      aug.close if aug
    end
  end

  def self.instances
    get_resources(file)
  end

  def self.prefetch(resources)
    targets = []
    resources.each do |name, resource|
      targets << file(resource) unless targets.include? file(resource)
    end
    hosts = targets.inject([]) { |hosts,target| hosts += get_resources(target) }
    resources.each do |name, resource|
      if provider = hosts.find { |host| (host.name == name and host.target == file(resource)) }
        resources[name].provider = provider
      end
    end
  end

  def exists? 
    @property_hash[:ensure] == :present and @property_hash[:target] == self.class.file(resource)
  end

  def create 
    aug = nil
    file = self.class.file(resource)
    path = "/files#{file}"
    begin
      aug = self.class.augopen(file)
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
      @property_hash = {
        :ensure => :present,
        :name => resource.name,
        :target => file,
        :ip => resource[:ip],
        :host_aliases => resource[:host_aliases],
      }
      if Puppet::Type.type(:host).validattr? :comment and resource[:comment]
        @property_hash[:comment] = resource[:comment] || ""
      end
    ensure
      aug.close if aug
    end
  end

  def destroy
    aug = nil
    file = self.class.file(resource)
    path = "/files#{file}"
    begin
      aug = self.class.augopen(file)
      aug.rm("#{path}/*[canonical = '#{resource[:name]}']")
      augsave!(aug)
      @property_hash[:ensure] = :absent
    ensure
      aug.close if aug
    end
  end

  def target
    @property_hash[:target]
  end

  def ip
    @property_hash[:ip]
  end

  def ip=(value)
    aug = nil
    file = self.class.file(resource)
    path = "/files#{file}"
    begin
      aug = self.class.augopen(file)
      aug.set("#{path}/*[canonical = '#{resource[:name]}']/ipaddr", value)
      augsave!(aug)
    ensure
      aug.close if aug
    end
    @property_hash[:ip] = value
  end

  def host_aliases
    aliases = @property_hash[:host_aliases] || []
    if resource.should(:host_aliases).is_a? Array
      aliases
    else
      aliases.join(" ")
    end
  end

  def host_aliases=(values)
    aug = nil
    file = self.class.file(resource)
    path = "/files#{file}"
    entry = "#{path}/*[canonical = '#{resource[:name]}']"
    begin
      aug = self.class.augopen(file)
      aug.rm("#{entry}/alias")

      insafter = "canonical"
      values = values.split unless values.is_a? Array
      values.each do |halias|
        aug.insert("#{entry}/#{insafter}", "alias", false)
        aug.set("#{entry}/alias[last()]", halias)
        insafter = "alias[last()]"
      end

      augsave!(aug)
      @property_hash[:host_aliases] = values
    ensure
      aug.close if aug
    end
  end

  def comment
    @property_hash[:comment] || ""
  end

  def comment=(value)
    aug = nil
    file = self.class.file(resource)
    path = "/files#{file}"
    begin
      aug = self.class.augopen(file)
      if value.empty?
        aug.rm("#{path}/*[canonical = '#{resource[:name]}']/#comment")
      else
        aug.set("#{path}/*[canonical = '#{resource[:name]}']/#comment", value)
      end
      augsave!(aug)
      @property_hash[:comment] = value
    ensure
      aug.close if aug
    end
  end
end
