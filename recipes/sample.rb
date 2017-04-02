execute "pkg_update" do
  command node['nsd']['pkg_update_command']
  action :run
end

## service starts automatically with default configs on install
## this conflicts with unbound running on default port
## stop until configs are written to run on another port
package node['nsd']['pkg_names'] do
  action :upgrade
  notifies :stop, "service[nsd]", :immediately
end

nsd_resource_rndc_key_config 'main_rndc-key' do
  rndc_keys_data_bag node['nsd']['sample']['rndc_keys_data_bag']
  rndc_keys_data_bag_item node['nsd']['sample']['rndc_keys_data_bag_item']
  rndc_key_names node['nsd']['sample']['rndc_key_names']

  path '/etc/nsd/nsd.conf.d/rndc-key.conf'
  notifies :restart, "service[nsd]", :delayed
end

nsd_git_zones 'main_nsd-zones' do
  git_repo node['nsd']['sample']['git_repo']
  git_branch node['nsd']['sample']['git_branch']
  release_path node['nsd']['sample']['release_path']
  zone_options node['nsd']['sample']['zone_options']

  path '/etc/nsd/nsd.conf.d/zones.conf'
  notifies :reload, "service[nsd]", :delayed
end

nsd_config 'nsd' do
  config node['nsd']['sample']['config']
  action :create
  notifies :restart, "service[nsd]", :delayed
end

include_recipe "nsd::init_service"
