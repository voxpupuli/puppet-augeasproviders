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
  defaultfor :feature => :augeas

  default_file { '/etc/aliases' }
  lens { 'Aliases.lns' }

  def self.unquote_val(value)
    if value =~ /^"(.*)"$/
      $1
    else
      value
    end
  end

  def self.quote_val(value)
    if value =~ /\s/
      "\"#{value}\""
    else
      value
    end
  end

  def self.get_resource(aug, apath, target)
    malias = {
      :ensure => :present,
      :target => target
    }
    return nil unless malias[:name] = aug.get("#{apath}/name")

    rcpts = aug.match("#{apath}/value").map { |p| unquote_val(aug.get(p)) }
    malias[:recipient] = rcpts
    malias
  end

  def self.get_resources(resource=nil)
    aug = nil
    file = target(resource)
    augopen(resource) do |aug, path|
      aug = augopen(resource)
      resources = aug.match("#{path}/*").map {
        |p| get_resource(aug, p, file)
      }.compact.map { |r| new(r) }
      resources
    end
  end

  def self.instances
    get_resources
  end

  def self.prefetch(resources)
    targets = []
    resources.each do |name, resource|
      targets << target(resource) unless targets.include? target(resource)
    end
    maliases = []
    targets.each do |target|
      maliases += get_resources({:target => target})
    end
    maliases = targets.inject([]) { |malias ,target| maliases += get_resources({:target => target}) }
    resources.each do |name, resource|
      if provider = maliases.find{ |malias| (malias.name == name and malias.target == target(resource)) }
        resources[name].provider = provider
      end
    end
  end

  def exists? 
    @property_hash[:ensure] == :present and @property_hash[:target] == self.class.target(resource)
  end

  def create 
    self.class.augopen(resource) do |aug, path|
      aug = self.class.augopen(resource)
      aug.set("#{path}/01/name", resource[:name])

      resource[:recipient].each do |rcpt|
        aug.set("#{path}/01/value[last()+1]", self.class.quote_val(rcpt))
      end

      augsave!(aug)
      @property_hash = {
        :ensure => :present,
        :name => resource.name,
        :target => self.class.target(resource),
        :recipient => resource[:recipient]
      }
    end
  end

  def destroy
    self.class.augopen(resource) do |aug, path|
      aug = self.class.augopen(resource)
      aug.rm("#{path}/*[name = '#{resource[:name]}']")
      augsave!(aug)
      @property_hash[:ensure] = :absent
    end
  end

  def target
    @property_hash[:target]
  end

  def recipient
    @property_hash[:recipient]
  end

  def recipient=(values)
    self.class.augopen(resource) do |aug, path|
      entry = "#{path}/*[name = '#{resource[:name]}']"
      aug = self.class.augopen(resource)
      aug.rm("#{entry}/value")

      values.each do |rcpt|
        aug.set("#{entry}/value[last()+1]", self.class.quote_val(rcpt))
      end

      augsave!(aug)
      @property_hash[:recipient] = values
    end
  end
end
