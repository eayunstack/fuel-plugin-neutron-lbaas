class lbaas::params {

  if ($::osfamily == 'RedHat') {
    $server_service     = 'neutron-server'

    $lbaas_agent_service   = 'neutron-lbaas-agent'

    $dashboard_service  = 'httpd'
    $dashboard_settings = '/etc/openstack-dashboard/local_settings'

    $haproxy_package    = 'haproxy'
  } else {
    fail("Unsopported osfamily ${::osfamily}")
  }

}
