# Alternative Augeas-based provider for mailalias type (Puppet builtin)
#
# Copyright (c) 2012 Dominic Cleal
# Licensed under the Apache License, Version 2.0

require File.dirname(__FILE__) + '/../../../augeasproviders/provider'

Puppet::Type.type(:mailalias).provide(:augeas) do
  desc "Uses Augeas API to update mail aliases file"

  include AugeasProviders::Provider

  confine :feature => :augeas
  confine :exists => "/etc/aliases"

  def self.file(resource = nil)
    file = "/etc/aliases"
    file = resource[:target] if resource and resource[:target]
    file.chomp("/")
  end

  def self.augopen(target)
    AugeasProviders::Provider.augopen("Aliases.lns", target)
  end

  def self.get_resource(aug, apath, target)
    malias = {
      :ensure => :present,
      :target => target
    }
    return nil unless malias[:name] = aug.get("#{apath}/name")

    rcpts = aug.match("#{apath}/value").map { |p| aug.get(p) }
    malias[:recipient] = rcpts
    malias
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
    maliases = []
    targets.each do |target|
      maliases += get_resources(target)
    end
    maliases = targets.inject([]) { |malias ,target| maliases += get_resources(target) }
    resources.each do |name, resource|
      if provider = maliases.find{ |malias| (malias.name == name and malias.target == file(resource)) }
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
      aug.set("#{path}/01/name", resource[:name])

      resource[:recipient].each do |rcpt|
        aug.set("#{path}/01/value[last()+1]", rcpt)
      end

      augsave!(aug)
      @property_hash = {
        :ensure => :present,
        :name => resource.name,
        :target => file,
        :recipient => resource[:recipient]
      }
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
      aug.rm("#{path}/*[name = '#{resource[:name]}']")
      augsave!(aug)
      @property_hash[:ensure] = :absent
    ensure
      aug.close if aug
    end
  end

  def target
    @property_hash[:target]
  end

  def recipient
    @property_hash[:recipient]
  end

  def recipient=(values)
    aug = nil
    file = self.class.file(resource)
    path = "/files#{file}"
    entry = "#{path}/*[name = '#{resource[:name]}']"
    begin
      aug = self.class.augopen(file)
      aug.rm("#{entry}/value")

      values.each do |rcpt|
        aug.set("#{entry}/value[last()+1]", rcpt)
      end

      augsave!(aug)
      @property_hash[:recipient] = values
    ensure
      aug.close if aug
    end
  end
end
