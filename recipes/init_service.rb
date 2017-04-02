package 'procps' do
  action :upgrade
end

service 'nsd' do
  # provider Chef::Provider::Service::Init
  start_command "/etc/init.d/nsd start"
  stop_command "/etc/init.d/nsd stop"
  restart_command "/etc/init.d/nsd restart"
  reload_command "/etc/init.d/nsd start && /usr/sbin/nsd-control reload"
  status_command "/etc/init.d/nsd status"
  action [:start]
end
