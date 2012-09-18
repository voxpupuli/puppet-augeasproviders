# Alternative Augeas-based providers for Puppet
#
# Copyright (c) 2012 Raphaël Pinson
# Licensed under the Apache License, Version 2.0

require 'augeasproviders/provider'

Puppet::Type.type(:sshd_config).provide(:augeas) do
  desc "Uses Augeas API to update an sshd_config parameter"

  include AugeasProviders::Provider

  def self.file(resource = nil)
    file = "/etc/ssh/sshd_config"
    file = resource[:target] if resource and resource[:target]
    file.chomp("/")
  end

  confine :feature => :augeas
  confine :exists => file

  def self.augopen(resource = nil)
    AugeasProviders::Provider.augopen("Sshd.lns", file(resource))
  end

  def self.path_label(path)
    path.split("/")[-1].split("[")[0]
  end

  def self.get_value(aug, pathx)
    aug.match(pathx).map do |vp|
      # Bug in Augeas lens, counter isn't reset to 1 so check for any int
      if aug.match("#{vp}/*[label()=~regexp('[0-9]*')]").empty?
        aug.get(vp)
      else
        aug.match("#{vp}/*").map do |svp|
          aug.get(svp)
        end
      end
    end.flatten
  end

  def self.set_value(aug, path, value)
    if path =~ /.*\/(((Allow|Deny)(Groups|Users))|AcceptEnv|MACs)(\[\d\*\])?/
      # Make sure only our values are used
      aug.rm("#{path}/*")
      # In case there is more than one entry, keep only the first one
      aug.rm("#{path}[position() != 1]")
      count = 0
      value.each do |v|
        count += 1
        aug.set("#{path}/#{count}", v)
      end
    else
      # Normal setting: one value per entry
      value = value.clone

      # Change any existing settings with this name
      aug.match(path).each do |sp|
        aug.set(sp, value.shift)
      end

      # Insert new values for the rest
      value.each do |v|
        unless aug.match("#{path}/../Match").empty?
          aug.insert("#{path}/../Match[1]", path_label(path), true)
        end
        aug.set("#{path}[last()]", v)
      end
    end
  end

  def self.instances
    aug = nil
    begin
      resources = []
      aug = augopen

      # Ordinary settings outside of match blocks
      # Find all unique setting names, then find all instances of it
      settings = aug.match("/files#{file}/*[label()!='Match']").map {|spath|
        self.path_label(spath)
      }.uniq.reject {|name| name.start_with?("#", "@")}

      settings.each do |name|
        value = self.get_value(aug, "/files#{file}/#{name}")
        entry = {:ensure => :present, :name => name, :value => value}
        resources << new(entry) if entry[:value]
      end

      # Settings inside match blocks
      aug.match("/files#{file}/Match").each do |mpath|
        conditions = []
        aug.match("#{mpath}/Condition/*").each do |cond_path|
          cond_name = self.path_label(cond_path)
          cond_value = aug.get(cond_path)
          conditions.push("#{cond_name} #{cond_value}")
        end
        cond_str = conditions.join(" ")

        settings = aug.match("#{mpath}/Settings/*").map {|spath|
          self.path_label(spath)
        }.uniq.reject {|name| name.start_with?("#", "@")}

        settings.each do |name|
          value = self.get_value(aug, "#{mpath}/Settings/#{name}")
          entry = {:ensure => :present, :name => name,
                   :value => value, :condition => cond_str}
          resources << new(entry) if entry[:value]
        end
      end

      resources
    ensure
      aug.close if aug
    end
  end

  def self.match_conditions(resource=nil)
    if resource[:condition]
      conditions = Hash[*resource[:condition].split(' ').flatten(1)]
      cond_keys = conditions.keys.length
      cond_str = "[count(Condition/*)=#{cond_keys}]"
      conditions.each { |k,v| cond_str += "[Condition/#{k}=\"#{v}\"]" }
      cond_str
    else
      ""
    end
  end

  def self.entry_path(resource)
    path = "/files#{self.file(resource)}"
    key = resource[:key] ? resource[:key] : resource[:name]
    if resource[:condition]
      cond_str = self.match_conditions(resource)
      "#{path}/Match#{cond_str}/Settings/#{key}"
    else
      "#{path}/#{key}"
    end
  end

  def self.match_exists?(resource)
    aug = nil
    path = "/files#{self.file(resource)}"
    begin
      aug = self.augopen(resource)
      if resource[:condition]
        cond_str = self.match_conditions(resource)
      else
        false
      end
      not aug.match("#{path}/Match#{cond_str}").empty?
    ensure
      aug.close if aug
    end
  end

  def exists? 
    aug = nil
    entry_path = self.class.entry_path(resource)
    begin
      aug = self.class.augopen(resource)
      not aug.match(entry_path).empty?
    ensure
      aug.close if aug
    end
  end

  def self.create_match(resource=nil, aug=nil)
    path = "/files#{self.file(resource)}"
    begin
      aug.insert("#{path}/*[last()]", "Match", false)
      conditions = Hash[*resource[:condition].split(' ').flatten(1)]
      conditions.each do |k,v|
        aug.set("#{path}/Match[last()]/Condition/#{k}", v)
      end
      aug
    end
  end

  def create 
    aug = nil
    path = "/files#{self.class.file(resource)}"
    entry_path = self.class.entry_path(resource)
    key = resource[:key] ? resource[:key] : resource[:name]
    begin
      aug = self.class.augopen(resource)
      if resource[:condition]
        unless self.class.match_exists?(resource)
          aug = self.class.create_match(resource, aug)
        end
      else
        unless aug.match("#{path}/Match").empty?
          aug.insert("#{path}/Match[1]", key, true)
        end
      end
      self.class.set_value(aug, entry_path, resource[:value])
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
      entry_path = self.class.entry_path(resource)
      aug.rm(entry_path)
      aug.rm("#{path}/Match[count(Settings/*)=0]")
      augsave!(aug)
    ensure
      aug.close if aug
    end
  end

  def target
    self.class.file(resource)
  end

  def value
    aug = nil
    path = "/files#{self.class.file(resource)}"
    begin
      aug = self.class.augopen(resource)
      entry_path = self.class.entry_path(resource)
      self.class.get_value(aug, entry_path)
    ensure
      aug.close if aug
    end
  end

  def value=(value)
    aug = nil
    path = "/files#{self.class.file(resource)}"
    begin
      aug = self.class.augopen(resource)
      entry_path = self.class.entry_path(resource)
      self.class.set_value(aug, entry_path, value)
      augsave!(aug)
    ensure
      aug.close if aug
    end
  end
end
