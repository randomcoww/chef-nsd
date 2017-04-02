node.default['nsd']['pkg_update_command'] = "apt-get update -qqy"
node.default['nsd']['pkg_names'] = ['nsd', 'git', 'procps']

node.default['nsd']['sample']['rndc_keys_data_bag'] = 'deploy_config'
node.default['nsd']['sample']['rndc_keys_data_bag_item'] = 'rndc_keys'
node.default['nsd']['sample']['rndc_key_names'] = ['rndc-test-key']

node.default['nsd']['sample']['git_repo'] = "https://github.com/randomcoww/nsd-config.git"
node.default['nsd']['sample']['git_branch'] = "test"
node.default['nsd']['sample']['release_path'] = ::File.join(Chef::Config[:file_cache_path], 'nsd')
node.default['nsd']['sample']['zone_options'] = {
  'zones' => {
  }
}

node.default['nsd']['sample']['config'] = {
  'include' => '/etc/nsd/nsd.conf.d/*.conf',
  'server' => {
    "do-ip4" => "yes",
    "ip-address" => "0.0.0.0",
    "port" => 53530,
    "username" => "nsd",
    "hide-version" => true,
    "zonesdir" => node['nsd']['sample']['release_path']
  },
  'remote-control' => {
    'control-enable' => true
  }
}
