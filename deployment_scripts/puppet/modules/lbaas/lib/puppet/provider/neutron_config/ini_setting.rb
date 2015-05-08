Puppet::Type.type(:neutron_config).provide(
  :ini_setting,
  :parent => Puppet::Type.type(:ini_setting).provider(:ruby)
) do

  def section
    resource[:name].split('/', 2).first
  end

  def setting
    resource[:name].split('/', 2).last
  end

  def separator
    '='
  end

  def file_path
    '/etc/neutron/neutron.conf'
  end

  def create
    append_value
    super
  end

  def value=(value)
    append_value
    super
  end

  private
  def append_value
    if resource[:append_to_list] and exists?
      c_list = value.strip.split(',')
      resource[:value] = c_list.push(resource[:value]).uniq.join(',')
    end
  end

end
