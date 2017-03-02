execute "pkg_update" do
  command node['nsd']['pkg_update_command']
  action :run
end

package node['nsd']['pkg_names'] do
  action :upgrade
end

node['nsd']['instances'].each do |name, v|
  nsd name do
    release_path ::File.join(Chef::Config[:file_cache_path], 'nsd', name)
    git_repo v['git_repo']
    git_branch v['git_branch']

    rndc_keys_data_bag v['rndc_keys_data_bag']
    rndc_keys_data_bag_item v['rndc_keys_data_bag_item']
    rndc_key_names v['rndc_key_names']

    server_options v['server_options']
    zone_options v['zone_options']

    remote_controls []
    patterns []

    action :deploy
  end
end
