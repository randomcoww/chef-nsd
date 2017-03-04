node.default['nsd']['pkg_update_command'] = "apt-get update -qqy"
node.default['nsd']['pkg_names'] = ['git', 'nsd']

node.default['nsd']['instances']['test'] = {
  'git_repo' => "https://github.com/randomcoww/nsd-config.git",
  'git_branch' => "test",

  'rndc_keys_data_bag' => 'deploy_config',
  'rndc_keys_data_bag_item' => 'rndc_keys',
  'rndc_key_names' => ['rndc-key-test'],

  'server_options' => {
    "do-ip4" => "yes",
    "port" => 53,
    "username" => "nsd",
    "pidfile" => "/var/run/nsd.pid",
    "hide-version" => "yes"
  },

  'zone_options' => {
    'zones' => {
      'allow-axfr-fallback' => 'yes'
    }
  }
}
