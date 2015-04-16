class lbaas (
  $lbaas_interface_driver = 'neutron.agent.linux.interface.OVSInterfaceDriver',
  $lbaas_ovs_use_veth     = true,
  $lbaas_device_driver    = 'neutron.services.loadbalancer.drivers.haproxy.namespace_driver.HaproxyNSDriver',
  $lbaas_plugin           = 'neutron.services.loadbalancer.plugin.LoadBalancerPlugin',
) {

  include lbaas::params

  package { $lbaas::params::haproxy_package:
    ensure => present,
  }

  service { $lbaas::params::lbaas_agent_service:
    ensure => running,
    enable => true,
  }

  neutron_lbaas_config {
    'DEFAULT/interface_driver': value => $lbaas_interface_driver;
    'DEFAULT/ovs_use_veth':     value => $lbaas_ovs_use_veth;
    'DEFAULT/device_driver':    value => $lbaas_device_driver;
  }

  Neutron_lbaas_config<||> ~> Service[$lbaas::params::lbaas_agent_service]

  service { $lbaas::params::server_service:
    ensure => running,
    enable => true,
  }

  neutron_config { 'DEFAULT/service_plugins':
    value          => $lbaas_plugin,
    append_to_list => true,
  }

  Neutron_config<||> ~> Service[$lbaas::params::server_service]

  service { $lbaas::params::dashboard_service:
    ensure => running,
    enable => true,
  }

  exec { 'enable_lbaas_dashboard':
    command => "/bin/echo \"OPENSTACK_NEUTRON_NETWORK['enable_lb'] = True\" >> $lbaas::params::dashboard_settings",
    unless  => "/bin/egrep \"^OPENSTACK_NEUTRON_NETWORK['enable_lb'] = True\" $lbaas:params::dashboard_settings",
  }

  Exec['enable_lbaas_dashboard'] ~> Service[$lbaas::params::dashboard_service]

}
