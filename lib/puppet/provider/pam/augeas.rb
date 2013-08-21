# Alternative Augeas-based providers for Puppet
#
# Copyright (c) 2012 Greg Swift
# Licensed under the Apache License, Version 2.0

require File.dirname(__FILE__) + '/../../../augeasproviders/provider'

Puppet::Type.type(:pam).provide(:augeas) do
  desc "Uses Augeas API to update an pam parameter"

  include AugeasProviders::Provider

  # Boolean is the key because they either do or do not provide a
  # value for control to work against.  Module doesn't work against
  # control
  PAM_INS_ALIASES = {
      true  => { 'first'  => "*[type='%s' and control='%s'][1]",
                 'last'   => "*[type='%s' and control='%s'][last()]",
                 'module' => "*[type='%s' and module='%s'][1]", },
      false => { 'first'  => "*[type='%s'][1]",
                 'last'   => "*[type='%s'][last()]", },
  }

  def self.file(resource = nil)
    file = "/etc/pam.d/#{resource[:service]}" if resource
    file = resource[:target] if resource and resource[:target]
    file.chomp("/")
  end

  confine :feature => :augeas
  confine :exists  => file

  def self.augopen(resource = nil)
    if file == "/etc/pam.conf"
       lense = "pamconf.lns"
    else
       lense = "pam.lns"
    end
    AugeasProviders::Provider.augopen(lense, file(resource))
  end

  def self.entry_path(resource)
    fpath = "/files#{self.file(resource)}"
    service = resource[:service]
    type = resource[:type]
    mod = resource[:module]
    if self.file(resource) == '/etc/pam.conf'
      "#{fpath}/*[service='#{service}' and type='#{type}' and module='#{mod}']"
    else
      "#{fpath}/*[type='#{type}' and module='#{mod}']"
    end
  end

  def self.instances
    aug = nil
    path = "/files#{file}"
    begin
      resources = []
      aug = augopen
      aug.match("#{path}/*").each do |epath|
        service = nil
        if self.class.file(resource) == '/etc/pam.conf'
          service = aug.get("#{epath}/service")
        end
        no_sync = aug.match("#{path}/action/no_sync").empty? ? :false : :true
        type = aug.get("#{epath}/type")
        control = aug.get("#{epath}/control")
        mod = aug.get("#{epath}/module")
        arguments = []
        aug.match("#{epath}/argument").each do |apath|
          arguments << aug.get(apath)
        end
        entry = {:ensure    => :present,
                 :service   => service,
                 :optional  => optional,
                 :type      => type,
                 :control   => control,
                 :module    => mod,
                 :arguments => arguments}
        resources << new(entry)
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
    path = "01"
    entry_path = "#{fpath}/#{path}"
    # we pull type, control, and order out because we actually
    # work with those values, not just reference them in the set section
    type = resource[:type].to_s
    control = resource[:control]
    begin
      aug = self.class.augopen(resource)
      if resource[:order]
        order = resource[:order]
      else
        order = 'before last'
      end
      placement, identifier, value = order.split(/ /)
      key = value ? true : false
      if PAM_INS_ALIASES[key].has_key?(identifier)
        expr = PAM_INS_ALIASES[key][identifier]
        expr = key ? expr % [type, value] : expr % [type]
      else
        # if the identifier is not in the mapping
        # we assume that its an xpath and so 
        # join everything after the placement 
        identifier = order.split(/ /)[1..-1].join(" ")
        expr = identifier
      end
      aug.insert("#{fpath}/#{expr}", path, placement == 'before' ? true : false)
      if resource[:optional] == :true
        aug.clear("#{entry_path}/optional")
      end
      if self.class.file(resource) == '/etc/pam.conf'
        aug.set("#{entry_path}/service", resource[:service])
      end
      aug.set("#{entry_path}/type", type)
      aug.set("#{entry_path}/control", control)
      aug.set("#{entry_path}/module", resource[:module])
      if resource[:arguments]
        arguments = resource[:arguments]
        arguments = arguments.split unless arguments.is_a? Array
        arguments.each do |argument|
          aug.set("#{entry_path}/argument[last()+1]", argument)
        end
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

  def optional
    aug = nil
    path = "/files#{self.class.file(resource)}"
    begin
      aug = self.class.augopen(resource)
      entry_path = self.class.entry_path(resource)
      if aug.match("#{entry_path}/optional").empty?
        :false
      else
        :true
      end
    ensure
      aug.close if aug
    end
  end

  def optional=(values)
    aug = nil
    path = "/files#{self.class.file(resource)}"
    begin
      aug = self.class.augopen(resource)
      entry_path = self.class.entry_path(resource)
      if resource[:optional] == :true
        if aug.match("#{entry_path}/optional").empty?
          aug.clear("#{entry_path}/optional")
        end
      else
        aug.rm("#{entry_path}/optional")
      end
      augsave!(aug)
    ensure
      aug.close if aug
    end
  end

  def control
    aug = nil
    path = "/files#{self.class.file(resource)}"
    begin
      aug = self.class.augopen(resource)
      entry_path = self.class.entry_path(resource)
      aug.get("#{entry_path}/control")
    ensure
      aug.close if aug
    end
  end

  def control=(values)
    aug = nil
    path = "/files#{self.class.file(resource)}"
    begin
      aug = self.class.augopen(resource)
      entry_path = self.class.entry_path(resource)
      aug.set("#{entry_path}/control", values)
      augsave!(aug)
    ensure
      aug.close if aug
    end
  end

  def arguments
    aug = nil
    path = "/files#{self.class.file(resource)}"
    begin
      aug = self.class.augopen(resource)
      arguments = []
      entry_path = self.class.entry_path(resource)
      aug.match("#{entry_path}/argument").each do |apath|
        arguments << aug.get(apath)
      end
      if resource.should(:arguments).is_a? Array
        arguments
      else
        arguments.join(" ")
      end
    ensure
      aug.close if aug
    end
  end

  def arguments=(values)
    aug = nil
    aug = nil
    path = "/files#{self.class.file(resource)}"
    begin
      aug = self.class.augopen(resource)
      entry_path = self.class.entry_path(resource)
      aug.rm("#{entry_path}/argument")
      insafter "module"
      values = values.split unless values.is_a? Array
      values.each do |argument|
        aug.insert("#{entry_path}/#{insafter}", "argument", false)
        aug.set("#{entry_path}/argument[last()]", argument)
        insafter = "argument[last()]"
      end
      augsave!(aug)
    ensure
      aug.close if aug
    end
  end

end
