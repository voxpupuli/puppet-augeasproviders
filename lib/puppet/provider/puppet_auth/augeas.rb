# Alternative Augeas-based providers for Puppet
#
# Copyright (c) 2012 Raphaël Pinson
# Licensed under the Apache License, Version 2.0

require File.dirname(__FILE__) + '/../../../augeasproviders/provider'

Puppet::Type.type(:puppet_auth).provide(:augeas) do
  desc "Uses Augeas API to update a rule in Puppet's auth.conf."

  include AugeasProviders::Provider

  INS_ALIASES = {
    "first allow" => "path[allow][1]",
    "last allow"  => "path[allow][last()]",
    "first deny"  => "path[count(allow)=0][1]",
    "last deny"   => "path[count(allow)=0][last()]",
  }

  def self.file(resource = nil)
    file = "/etc/puppet/auth.conf"
    file = resource[:target] if resource and resource[:target]
    file.chomp("/")
  end

  confine :feature => :augeas
  confine :exists => file

  def self.augopen(resource = nil)
    AugeasProviders::Provider.augopen("Puppet_Auth.lns", file(resource))
  end

  def self.entry_path(resource)
    fpath = "/files#{self.file(resource)}"
    path = resource[:path]

    "#{fpath}/path[.='#{path}']"
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

  def self.set_value_m(aug, pathx, values)
    if values.nil?
      aug.rm(pathx)
    else
      # Make sure only our values are used
      aug.rm("#{pathx}/*")
      # In case there is more than one entry, keep only the first one
      aug.rm("#{pathx}[position() != 1]")
      count = 0
      values.each do |v|
        count += 1
        aug.set("#{pathx}/#{count}", v)
      end
    end
  end

  def self.instances
    aug = nil
    begin
      resources = []
      aug = augopen

      settings = aug.match("/files#{file}/path")

      settings.each do |node|
        path = self.get_value(aug, node)
        path_regex = aug.match("#{node}/operator[.='~']").empty? ? :false : :true
        environments = self.get_value(aug, "#{node}/environment")
        methods = self.get_value(aug, "#{node}/method")
        allow = self.get_value(aug, "#{node}/allow")
        allow_ip = self.get_value(aug, "#{node}/allow_ip")
        authenticated = self.get_value(aug, "#{node}/auth")
        name = (path_regex == :false) ? "Auth rule for #{path.first}" : "Auth rule matching #{path.first}"
        entry = {:ensure => :present, :name => name,
                 :path => path, :path_regex => path_regex,
                 :environments => environments, :methods => methods,
                 :allow => allow, :allow_ip => allow_ip,
                 :authenticated => authenticated}
        resources << new(entry) if entry[:path]
      end

      resources
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

  def create
    aug = nil
    fpath = "/files#{self.class.file(resource)}"
    entry_path = self.class.entry_path(resource)
    path = resource[:path]
    path_regex = resource[:path_regex]
    before = resource[:ins_before]
    after = resource[:ins_after]
    environments = resource[:environments]
    methods = resource[:methods]
    allow = resource[:allow]
    allow_ip = resource[:allow_ip]
    authenticated = resource[:authenticated]
    begin
      aug = self.class.augopen(resource)
      if before or after
        expr = before || after
        if INS_ALIASES.has_key?(expr)
          expr = INS_ALIASES[expr]
        end
        aug.insert("#{fpath}/#{expr}", "path", before ? true : false)
        aug.set("#{fpath}/path[.='']", path)
      end

      aug.set(entry_path, path)
      if path_regex == :true
        aug.set("#{entry_path}/operator", "~")
      end
      self.class.set_value_m(aug, "#{entry_path}/environment", environments)
      self.class.set_value_m(aug, "#{entry_path}/method", methods)
      self.class.set_value_m(aug, "#{entry_path}/allow", allow)
      self.class.set_value_m(aug, "#{entry_path}/allow_ip", allow_ip)
      aug.set("#{entry_path}/auth", authenticated)
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
      augsave!(aug)
    ensure
      aug.close if aug
    end
  end

  def target
    self.class.file(resource)
  end

  def environments
    aug = nil
    path = "/files#{self.class.file(resource)}"
    begin
      aug = self.class.augopen(resource)
      entry_path = self.class.entry_path(resource)
      self.class.get_value(aug, "#{entry_path}/environment")
    ensure
      aug.close if aug
    end
  end

  def environments=(values)
    aug = nil
    aug = nil
    path = "/files#{self.class.file(resource)}"
    begin
      aug = self.class.augopen(resource)
      entry_path = self.class.entry_path(resource)
      self.class.set_value_m(aug, "#{entry_path}/environment", values)
      augsave!(aug)
    ensure
      aug.close if aug
    end
  end

  def methods
    aug = nil
    path = "/files#{self.class.file(resource)}"
    begin
      aug = self.class.augopen(resource)
      entry_path = self.class.entry_path(resource)
      self.class.get_value(aug, "#{entry_path}/method")
    ensure
      aug.close if aug
    end
  end

  def methods=(values)
    aug = nil
    aug = nil
    path = "/files#{self.class.file(resource)}"
    begin
      aug = self.class.augopen(resource)
      entry_path = self.class.entry_path(resource)
      self.class.set_value_m(aug, "#{entry_path}/method", values)
      augsave!(aug)
    ensure
      aug.close if aug
    end
  end

  def allow
    aug = nil
    path = "/files#{self.class.file(resource)}"
    begin
      aug = self.class.augopen(resource)
      entry_path = self.class.entry_path(resource)
      self.class.get_value(aug, "#{entry_path}/allow")
    ensure
      aug.close if aug
    end
  end

  def allow=(values)
    aug = nil
    aug = nil
    path = "/files#{self.class.file(resource)}"
    begin
      aug = self.class.augopen(resource)
      entry_path = self.class.entry_path(resource)
      self.class.set_value_m(aug, "#{entry_path}/allow", values)
      augsave!(aug)
    ensure
      aug.close if aug
    end
  end

  def allow_ip
    aug = nil
    path = "/files#{self.class.file(resource)}"
    begin
      aug = self.class.augopen(resource)
      entry_path = self.class.entry_path(resource)
      self.class.get_value(aug, "#{entry_path}/allow_ip")
    ensure
      aug.close if aug
    end
  end

  def allow_ip=(values)
    aug = nil
    aug = nil
    path = "/files#{self.class.file(resource)}"
    begin
      aug = self.class.augopen(resource)
      entry_path = self.class.entry_path(resource)
      self.class.set_value_m(aug, "#{entry_path}/allow_ip", values)
      augsave!(aug)
    ensure
      aug.close if aug
    end
  end

  def authenticated
    aug = nil
    path = "/files#{self.class.file(resource)}"
    begin
      aug = self.class.augopen(resource)
      entry_path = self.class.entry_path(resource)
      aug.get("#{entry_path}/auth")
    ensure
      aug.close if aug
    end
  end

  def authenticated=(value)
    aug = nil
    path = "/files#{self.class.file(resource)}"
    begin
      aug = self.class.augopen(resource)
      entry_path = self.class.entry_path(resource)
      # In case there's more than one
      aug.rm("#{entry_path}/auth[position()!=-1]")
      aug.set("#{entry_path}/auth", value)
      augsave!(aug)
    ensure
      aug.close if aug
    end
  end
end
