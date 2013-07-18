# Manages pg_hba entries

require File.dirname(__FILE__) + '/../../augeasproviders/type'

Puppet::Type.newtype(:pg_hba) do
  @doc = "Manages commands in pg_hba.conf."

  extend AugeasProviders::Type

  positionable

  newparam(:name) do
    desc "The default namevar"
  end

  newparam(:type) do
    desc "The type of host"
    isnamevar
    newvalues('local', 'host', 'hostssl', 'hostnossl')
    defaultto('local')
    munge do |value|
      value.to_s
    end
  end

  newparam(:database) do
    isnamevar
    desc "The database"
    defaultto(['all'])

    munge do |value|
      if value.is_a? Array
        value
      else
        [value]
      end
    end
  end

  newparam(:user) do
    isnamevar
    desc "The user"
    defaultto(['all'])

    munge do |value|
      if value.is_a? Array
        value
      else
        [value]
      end
    end
  end

  newparam(:address) do
    isnamevar
    desc "The address (for host, hostssl, hostnossl types)"
    validate do |value|
      unless value.nil? or @resource[:type] != 'local'
        raise ArgumentError, "address makes no sense for a local type"
      end
    end
  end

  newparam(:target) do
    isnamevar
    desc "The file in which to the pg_hba rule"
  end

  def self.title_patterns
    identity = lambda { |x| x }
    comma_split = lambda { |x| x.split(',') }
    [
      [
        /^(local)\s+to\s+(\S+)\s+on\s+(\S+)\s+in\s+(.*)$/,
        [
          [ :type, identity ],
          [ :user, comma_split ],
          [ :database, comma_split ],
          [ :target, identity ],
        ]
      ],
      [
        /^(local)\s+to\s+(\S+)\s+on\s+(\S+)$/,
        [
          [ :type, identity ],
          [ :user, comma_split ],
          [ :database, comma_split ],
        ]
      ],
      [
        /^(host\S*)\s+to\s+(\S+)\s+on\s+(\S+)\s+from\s+(\S+)\s+in\s+(.*)$/,
        [
          [ :type, identity ],
          [ :user, comma_split ],
          [ :database, comma_split ],
          [ :address, identity ],
          [ :target, identity ]
        ]
      ],
      [
        /^(host\S*)\s+to\s+(\S+)\s+on\s+(\S+)\s+from\s+(\S+)$/,
        [
          [ :type, identity ],
          [ :user, comma_split ],
          [ :database, comma_split ],
          [ :address, identity ],
        ]
      ],
      [
        /(.*)/,
        [
          [ :name, identity ],
        ]
      ]
    ]
  end

  newparam(:position) do
    desc "Where to place the new entry"
    validate do |value|
      raise "Wrong position statement '#{value}'" unless value =~ /^(before|after)/
    end
  end

  newproperty(:method) do
    desc "The authentication method"
  end

  newproperty(:options) do
    desc "The hash of authentication options"
    defaultto({})
  end

  autorequire(:file) do
    self[:target]
  end
end
