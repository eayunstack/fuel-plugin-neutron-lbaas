$fuel_settings = parseyaml($astute_settings_yaml)

if $fuel_settings {
  class { 'lbaas':
    ha_mode => $fuel_settings['deployment_mode'] ? {
      'ha_compact' => true,
      default      => false,
    },
    primary_controller => $fuel_settings['role'] ? {
      'primary-controller' => true,
      default              => false
    },
  }
}
