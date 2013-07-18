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

  resource_path do |resource|
    "$target/*[name = '#{resource[:name]}']"
  end

  def self.get_resource(aug, apath, target)
    malias = {
      :ensure => :present,
      :target => target
    }
    return nil unless malias[:name] = aug.get("#{apath}/name")

    rcpts = aug.match("#{apath}/value").map { |p| unquoteit(aug.get(p)) }
    malias[:recipient] = rcpts
    malias
  end

  def self.get_resources(resource=nil)
    aug = nil
    file = target(resource)
    augopen(resource) do |aug|
      resources = aug.match("$target/*").map {
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
    augopen do |aug|
      aug.set("$target/01/name", resource[:name])

      resource[:recipient].each do |rcpt|
        aug.set("$target/01/value[last()+1]", quoteit(rcpt))
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
    augopen do |aug|
      aug.rm('$resource')
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
    augopen do |aug|
      aug.rm('$resource/value')

      values.each do |rcpt|
        aug.set('$resource/value[last()+1]', quoteit(rcpt))
      end

      augsave!(aug)
      @property_hash[:recipient] = values
    end
  end
end
