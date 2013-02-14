# Alternative Augeas-based providers for Puppet
#
# Copyright (c) 2012 Raphaël Pinson
# Licensed under the Apache License, Version 2.0

require File.dirname(__FILE__) + '/../../../augeasproviders/provider'

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
      # Augeas lens does transparent multi-node (no counte reset) so check for any int
      if aug.match("#{vp}/*[label()=~regexp('[0-9]*')]").empty?
        aug.get(vp)
      else
        aug.match("#{vp}/*").map do |svp|
          aug.get(svp)
        end
      end
    end.flatten
  end

  def self.set_value(aug, base, path, value)
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
      lastsp = nil
      aug.match(path).each do |sp|
        val = value.shift
        if val.nil?
          aug.rm(sp)
        else
          aug.set(sp, val)
          lastsp = sp
        end
      end

      # Insert new values for the rest
      label = path_label(path)
      value.each do |v|
        if lastsp
          # After the most recent same setting (lastsp)
          aug.insert(lastsp, label, false)
          aug.set("#{path}[last()]", v)
        else
          # Prefer to create the node next to a commented out entry
          commented = aug.match("#{base}/#comment[.=~regexp('#{label}([^a-z\.].*)?')]")
          if commented.empty?
            if aug.match("#{base}/Match").empty?
              # insert as the last line
              aug.insert("#{base}/*", label, false)
            else
              # before the match block so it's in the main section
              aug.insert("#{base}/Match[1]", label, true)
            end
          else
            aug.insert(commented.first, label, false)
          end
          aug.set("#{path}[last()]", v)
        end
        lastsp = aug.match("#{path}[last()]")[0]
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
      }.uniq.reject {|key| key.start_with?("#", "@")}

      settings.each do |key|
        value = self.get_value(aug, "/files#{file}/#{key}")
        entry = {:ensure => :present, :key => key, :value => value}
        resources << new(entry) if entry[:value]
      end

      # Settings inside match blocks
      aug.match("/files#{file}/Match").each do |mpath|
        conditions = []
        aug.match("#{mpath}/Condition/*").each do |cond_path|
          cond_key = self.path_label(cond_path)
          cond_value = aug.get(cond_path)
          conditions.push("#{cond_key} #{cond_value}")
        end
        cond_str = conditions.join(" ")

        settings = aug.match("#{mpath}/Settings/*").map {|spath|
          self.path_label(spath)
        }.uniq.reject {|key| key.start_with?("#", "@")}

        settings.each do |key|
          value = self.get_value(aug, "#{mpath}/Settings/#{key}")
          entry = {:ensure => :present, :key => key,
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
    key = resource[:key]
    base = if resource[:condition]
      "#{path}/Match#{self.match_conditions(resource)}/Settings"
    else
      path
    end
    { :base => base, :path => "#{base}/#{key}" }
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
    entry_path = self.class.entry_path(resource)[:path]
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
    key = resource[:key]
    begin
      aug = self.class.augopen(resource)
      if resource[:condition]
        unless self.class.match_exists?(resource)
          aug = self.class.create_match(resource, aug)
        end
      end
      self.class.set_value(aug, entry_path[:base], entry_path[:path], resource[:value])
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
      entry_path = self.class.entry_path(resource)[:path]
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
      entry_path = self.class.entry_path(resource)[:path]
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
      self.class.set_value(aug, entry_path[:base], entry_path[:path], value)
      augsave!(aug)
    ensure
      aug.close if aug
    end
  end
end
