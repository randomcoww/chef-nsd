class ChefNsd
  class Resource
    class Zone < Chef::Resource
      include NsdConfigGenerator

      resource_name :nsd_zone

      default_action :create
      allowed_actions :delete

      property :owner_name, String
      property :ttl, Integer, default: 300
      property :name_server, String
      property :email_addr, String
      property :sn, Integer, default: 2017010101
      property :ref, Integer, default: 28800
      property :ret, Integer, default: 14400
      property :ex, Integer, default: 604800
      property :nx, Integer, default: 86400

      property :hosts, Hash
      property :zone_options, Hash

      property :zone_path, String
      property :zonefile_path, String, default: lazy { ::File.join(zone_path, owner_name) }
      property :config_path, String


      action :create do
        with_run_context :root do

          directory zone_path do
            recursive :true
            action :create
          end

          template zonefile_path do
            source 'zonefile.erb'
            variables ({
              owner_name: new_resource.owner_name,
              ttl: new_resource.ttl,
              name_server: new_resource.name_server,
              email_addr: new_resource.email_addr,
              sn: new_resource.sn,
              ref: new_resource.ref,
              ret: new_resource.ret,
              ex: new_resource.ex,
              nx: new_resource.nx,
              hosts: new_resource.hosts
            })
          end

          edit_resource(:template, config_path) do |new_resource|
            cookbook 'chef-nsd'
            variables['content'] ||= []
            variables['content'] << generate_config('zone' => {
              'name' => owner_name,
              'zonefile' => zonefile_path
            }.merge(zone_options))

            action :nothing
            delayed_action :create
          end
        end
      end
    end
  end
end
