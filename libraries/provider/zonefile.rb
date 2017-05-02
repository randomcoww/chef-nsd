class ChefNsd
  class Provider
    class Zonefile < Chef::Provider
      include NsdConfigGenerator

      provides :nsd_zonefile, os: "linux"

      def load_current_resource
        @current_resource = ChefNsd::Resource::Zonefile.new(new_resource.name)
        current_resource
      end

      def action_create
        create_path
        nsd_zonefile.run_action(:create)
        new_resource.updated_by_last_action(nsd_zonefile.updated_by_last_action?)
      end


      private

      def create_path
        Chef::Resource::Directory.new(::File.dirname(new_resource.path), run_context).tap do |r|
          r.recursive true
        end.run_action(:create_if_missing)
      end

      def nsd_zonefile
        @nsd_zonefile ||= Chef::Resource::Template.new(new_resource.path, run_context).tap do |r|
          r.path new_resource.path
          r.cookbook 'nsd'
          r.source 'zonefile.erb'
          r.variables ({
            domain: new_resource.domain,
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
          ## NSD reload doesn't seem to pickup changes if updated with atomic_update
          r.atomic_update false
        end
      end
    end
  end
end
