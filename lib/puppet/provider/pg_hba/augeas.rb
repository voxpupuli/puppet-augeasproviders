# Alternative Augeas-based provider for pg_hba type

require File.dirname(__FILE__) + '/../../../augeasproviders/provider'

Puppet::Type.type(:pg_hba).provide(:augeas) do
  desc "Uses Augeas API to update pg_hba settings"

  include AugeasProviders::Provider

  ORDER_ALIASES = {
    "first entry"     => "*[type][1]",
    "last entry"      => "*[type][last()]",
    "first local"     => "*[type='local'][1]",
    "last local"      => "*[type='local'][last()]",
    "first host"      => "*[type='host'][1]",
    "last host"       => "*[type='host'][last()]",
    "first hostssl"   => "*[type='hostssl'][1]",
    "last hostssl"    => "*[type='hostssl'][last()]",
    "first hostnossl" => "*[type='hostnossl'][1]",
    "last hostnossl"  => "*[type='hostnossl'][last()]",
    "first anyhost"   => "*[type=~regexp('host.*')][1]",
    "last anyhost"    => "*[type=~regexp('host.*')][last()]",
  }

  confine :feature => :augeas

  lens { 'Pg_hba.lns' }

  resource_path do |resource|
    type = resource[:type]
    database = resource[:database]
    user = resource[:user]
    address = resource[:address]

    database_condition = database.map { |d| "database='#{d}'" }.join(' and ')
    database_condition += " and count(database)=#{database.size}"

    user_condition = user.map { |u| "user='#{u}'" }.join(' and ')
    user_condition += " and count(user)=#{user.size}"

    if type == 'local'
      "$target/*[type='#{type}' and #{database_condition} and #{user_condition}]"
    else
      "$target/*[type='#{type}' and #{database_condition} and #{user_condition} and address='#{address}']"
    end
  end

  def self.position_path (position)
    pos_before, pos_condition = position.match(/(before|after)\s+(.*)\s*/).captures
    if ORDER_ALIASES.has_key? pos_condition
      pos_path = ORDER_ALIASES[pos_condition]
    else
      pos_path = pos_condition
    end
    return pos_path, pos_before
  end

  def in_position?
    unless resource[:position].nil?
      aug = nil
      pos_path, pos_before = self.class.position_path(resource[:position])
      augopen do |aug|
        if pos_before == 'before'
          mpath = "#{resource_path}[following-sibling::#{pos_path}]"
        else
          mpath = "#{resource_path}[preceding-sibling::#{pos_path}]"
        end

        !aug.match(mpath).empty?
      end
    end
  end

  def create 
    augopen! do |aug|
      unless resource[:position].nil?
        pos_path, pos_before = self.class.position_path(resource[:position])
        aug.insert("$target/#{pos_path}", '01', pos_before == 'before')
      end
      aug.defnode('new', '$target/01', nil)

      aug.set("$new/type", resource[:type])

      resource[:database].each do |d|
        aug.set("$new/database[.='#{d}']", d)
      end

      resource[:user].each do |u|
        aug.set("$new/user[.='#{u}']", u)
      end

      if resource[:type] != 'local'
        aug.set("$new/address", resource[:address])
      end
      aug.set("$new/method", resource[:method])
      resource[:options].each do |o, v|
        aug.set("$new/method/option[.='#{o}']", o)
        unless v == :undef
          aug.set("$new/method/option[.='#{o}']/value", v)
        end
      end
    end
  end

  def method
    augopen do |aug|
      aug.get('$resource/method')
    end
  end

  def method=(method)
    augopen! do |aug|
      aug.set('$resource/method', method)
    end
  end

  def options
    augopen do |aug|
      options = {}
      aug.match('$resource/method/option').each do |o|
        value = aug.get("#{o}/value") || :undef
        options[aug.get(o)] = value
      end
      options
    end
  end

  def options=(options)
    augopen! do |aug|
      # First get rid of all options
      aug.rm('$resource/method/option')
      options.each do |o, v|
        aug.set("$resource/method/option[.='#{o}']", o)
        unless v == :undef
          aug.set("$resource/method/option[.='#{o}']/value", v)
        end
      end
    end
  end
end
