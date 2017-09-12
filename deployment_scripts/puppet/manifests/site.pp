$fuel_settings = parseyaml($astute_settings_yaml)

if $fuel_settings {
  $roles = node_roles($fuel_settings['nodes'], $fuel_settings['uid'])
  if 'primary-controller' in $roles {
    $is_primary_controller = true
  } else {
    $is_primary_controller = false
  }
  class { 'lbaas':
    ha_mode => $fuel_settings['deployment_mode'] ? {
      'ha_compact' => true,
      default      => false,
    },
    primary_controller => $is_primary_controller,
    auth_vip => $fuel_settings['management_vip'],
  }
}
