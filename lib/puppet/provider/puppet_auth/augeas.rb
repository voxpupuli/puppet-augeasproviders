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

  default_file { '/etc/puppet/auth.conf' }

  lens { 'Puppet_Auth.lns' }

  confine :feature => :augeas
  confine :exists => target

  resource_path do |resource|
    fpath = "/files#{target(resource)}"
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
    resources = []
    augopen do |aug, path|
      settings = aug.match("#{path}/path")

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
    end
    resources
  end

  def exists?
    augopen do |aug, path|
      not aug.match(resource_path).empty?
    end
  end

  def create
    apath = resource[:path]
    apath_regex = resource[:path_regex]
    before = resource[:ins_before]
    after = resource[:ins_after]
    environments = resource[:environments]
    methods = resource[:methods]
    allow = resource[:allow]
    allow_ip = resource[:allow_ip]
    authenticated = resource[:authenticated]
    augopen do |aug, path|
      if before or after
        expr = before || after
        if INS_ALIASES.has_key?(expr)
          expr = INS_ALIASES[expr]
        end
        aug.insert("#{path}/#{expr}", "path", before ? true : false)
        aug.set("#{path}/path[.='']", apath)
      end

      aug.set(resource_path, apath)
      if apath_regex == :true
        aug.set("#{resource_path}/operator", "~")
      end
      self.class.set_value_m(aug, "#{resource_path}/environment", environments)
      self.class.set_value_m(aug, "#{resource_path}/method", methods)
      self.class.set_value_m(aug, "#{resource_path}/allow", allow)
      self.class.set_value_m(aug, "#{resource_path}/allow_ip", allow_ip)
      aug.set("#{resource_path}/auth", authenticated)
      augsave!(aug)
    end
  end

  def destroy
    augopen do |aug, path|
      aug.rm(resource_path)
      augsave!(aug)
    end
  end

  def environments
    augopen do |aug, path|
      self.class.get_value(aug, "#{resource_path}/environment")
    end
  end

  def environments=(values)
    augopen do |aug, path|
      self.class.set_value_m(aug, "#{resource_path}/environment", values)
      augsave!(aug)
    end
  end

  def methods
    augopen do |aug, path|
      self.class.get_value(aug, "#{resource_path}/method")
    end
  end

  def methods=(values)
    augopen do |aug, path|
      self.class.set_value_m(aug, "#{resource_path}/method", values)
      augsave!(aug)
    end
  end

  def allow
    augopen do |aug, path|
      self.class.get_value(aug, "#{resource_path}/allow")
    end
  end

  def allow=(values)
    augopen do |aug, path|
      self.class.set_value_m(aug, "#{resource_path}/allow", values)
      augsave!(aug)
    end
  end

  def allow_ip
    augopen do |aug, path|
      self.class.get_value(aug, "#{resource_path}/allow_ip")
    end
  end

  def allow_ip=(values)
    augopen do |aug, path|
      self.class.set_value_m(aug, "#{resource_path}/allow_ip", values)
      augsave!(aug)
    end
  end

  def authenticated
    augopen do |aug, path|
      aug.get("#{resource_path}/auth")
    end
  end

  def authenticated=(value)
    augopen do |aug, path|
      # In case there's more than one
      aug.rm("#{resource_path}/auth[position()!=-1]")
      aug.set("#{resource_path}/auth", value)
      augsave!(aug)
    end
  end
end
