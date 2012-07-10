Puppet::Type.newtype(:sshd_config) do
  ensurable

  newparam(:name) do
    desc "The name of the entry."
    isnamevar
  end

  newparam(:key) do
    desc "Overrides name to prevent resource conflicts."
  end

  newproperty(:value) do
    desc "Entry value."
  end

  newproperty(:target) do
    desc "File target."
  end

  newparam(:condition) do
    desc "Match group condition for the entry."
  end
end
