service 'nsd' do
  provider Chef::Provider::Service::Init
  action [:start]
end
