class lbaas (
  $lbaas_interface_driver = 'neutron.agent.linux.interface.OVSInterfaceDriver',
  $lbaas_ovs_use_veth     = true,
  $lbaas_device_driver    = 'neutron.services.loadbalancer.drivers.haproxy.namespace_driver.HaproxyNSDriver',
  $lbaas_plugin           = 'neutron.services.loadbalancer.plugin.LoadBalancerPlugin',
  $ha_mode                = false,
  $primary_controller     = false,
) {

  include lbaas::params

  package { $lbaas::params::haproxy_package:
    ensure => present,
  }

  if $ha_mode {

    $service_ensure = 'stopped'
    $enabled        = false

    file { 'ocf-eayun-path':
      ensure  => directory,
      path    =>'/usr/lib/ocf/resource.d/eayun',
      recurse => true,
      owner   => 'root',
      group   => 'root',
    }

    file { 'lbaas-agent-ocf-file':
      path    => '/usr/lib/ocf/resource.d/eayun/neutron-agent-lbaas',
      mode    => '0755',
      owner   => 'root',
      group   => 'root',
      source  => "puppet:///modules/lbaas/ocf/neutron-agent-lbaas",
      require => File['ocf-eayun-path'],
    }

#fuel-plugins system doesn't have 'primary-controller' role so
#we have to separate controllers' deployment here using waiting cycles.

    if $primary_controller {

      cs_resource { "p_${lbaas::params::lbaas_agent_service}":
        ensure          => present,
        primitive_class => 'ocf',
        provided_by     => 'eayun',
        primitive_type  => 'neutron-agent-lbaas',
        complex_type    => 'clone',
        ms_metadata     => { 'interleave' => 'true' },
        operations      => {
          'monitor' => {
            'interval' => '20',
            'timeout'  => '10',
          },
          'start'   => {
            'timeout' => '80',
          },
          'stop'    => {
            'timeout' => '80',
          }
        }
      }

      File['lbaas-agent-ocf-file'] ->
        Cs_resource["p_${lbaas::params::lbaas_agent_service}"] ->
          Service[$lbaas::params::lbaas_agent_service]

    } else {

      exec {'waiting-for-lbaas-agent':
        tries     => 10,
        try_sleep => 20,
        command   => "pcs resource show p_neutron-lbaas-agent > /dev/null 2>&1",
        path      => '/usr/sbin:/usr/bin',
      }

      File['lbaas-agent-ocf-file'] ->
        Exec['waiting-for-lbaas-agent'] ->
          Service[$lbaas::params::lbaas_agent_service]

    }

    Service<| title == "${lbaas::params::lbaas_agent_service}" |> {
      enable     => true,
      ensure     => 'running',
      hasstatus  => true,
      hasrestart => false,
      provider   => 'pacemaker',
    }

  } else {

    $service_ensure = 'running'
    $enabled        = true

  }

  service { $lbaas::params::lbaas_agent_service:
    ensure => $service_ensure,
    enable => $enabled,
  }

  neutron_lbaas_config {
    'DEFAULT/interface_driver': value => $lbaas_interface_driver;
    'DEFAULT/ovs_use_veth':     value => $lbaas_ovs_use_veth;
    'DEFAULT/device_driver':    value => $lbaas_device_driver;
    'haproxy/user_group':       value => 'nobody';
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
