Puppet::Type.newtype(:neutron_config) do

  ensurable

  newparam(:name, :namevar => true) do
    desc 'Section/setting name to manage from neutron.conf'
    newvalues(/\S+\/\S+/)
  end

  newproperty(:value) do
    desc 'The value of the setting to be defined.'
    munge do |value|
      value = value.to_s.strip
      value.capitalize! if value =~ /^(true|false)$/i
      value
    end
  end

  newparam(:append_to_list, :boolean => true) do
    desc 'Whether the specified value is to be appended to the current ones'
    newvalues(:true, :false)
    defaultto false
  end

end
