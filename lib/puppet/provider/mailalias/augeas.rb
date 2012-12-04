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

  def self.augopen(resource = nil)
    AugeasProviders::Provider.augopen("Aliases.lns", file(resource))
  end

  def self.instances
    aug = nil
    path = "/files#{file}"
    begin
      resources = []
      aug = augopen
      aug.match("#{path}/*").each do |apath|
        malias = {:ensure => :present}
        malias[:name] = aug.get("#{apath}/name")
        next unless malias[:name]

        rcpts = []
        aug.match("#{apath}/value").each do |rcpt|
          rcpts << aug.get(rcpt)
        end
        malias[:recipient] = rcpts

        resources << new(malias)
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
      not aug.match("#{path}/*[name = '#{resource[:name]}']").empty?
    ensure
      aug.close if aug
    end
  end

  def create 
    aug = nil
    path = "/files#{self.class.file(resource)}"
    begin
      aug = self.class.augopen(resource)
      aug.set("#{path}/01/name", resource[:name])

      resource[:recipient].each do |rcpt|
        aug.set("#{path}/01/value[last()+1]", rcpt)
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
      aug.rm("#{path}/*[name = '#{resource[:name]}']")
      augsave!(aug)
    ensure
      aug.close if aug
    end
  end

  def target
    self.class.file(resource)
  end

  def recipient
    aug = nil
    path = "/files#{self.class.file(resource)}"
    begin
      aug = self.class.augopen(resource)
      aliases = []
      aug.match("#{path}/*[name = '#{resource[:name]}']/value").each do |apath|
        aliases << aug.get(apath)
      end
      aliases
    ensure
      aug.close if aug
    end
  end

  def recipient=(values)
    aug = nil
    path = "/files#{self.class.file(resource)}"
    entry = "#{path}/*[name = '#{resource[:name]}']"
    begin
      aug = self.class.augopen(resource)
      aug.rm("#{entry}/value")

      values.each do |rcpt|
        aug.set("#{entry}/value[last()+1]", rcpt)
      end

      augsave!(aug)
    ensure
      aug.close if aug
    end
  end
end
