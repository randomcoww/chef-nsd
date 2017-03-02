class Chef
  class Provider
    class Nsd < Chef::Provider
      include RndcKeysHelper

      provides :nsd, os: "linux"

      def load_current_resource
        @current_resource = Chef::Resource::Nsd.new(new_resource.name)
        current_resource
      end

      def action_deploy
        converge_by("Deploy nsd: #{new_resource.name}") do
          create_release_path

          current_revision = git_provider.find_current_revision
          Chef::Log.info("Current git revision: #{current_revision}")

          git_repo.run_action(:sync)
          nsd_config.run_action(:create)
          nsd_service(:start)

          begin
            nsd_control_reload_configs

          rescue
            git_repo.revision(current_revision)
            git_provider.git_reset

            nsd_config.variables nsd_config_variables
            nsd_config.run_action(:create)
            nsd_control_reload_configs
          end
        end
      end


      private

      def nsd_service(action)
        Chef::Resource::Service.new('nsd', run_context).tap do |r|
          r.provider Chef::Provider::Service::Systemd
        end.run_action(action)
      end

      def nsd_control_reload_configs
        if nsd_config.updated_by_last_action?
          nsd_service(:restart)
        end

        if git_repo.updated_by_last_action?
          nsd_service(:reload)
        end
      end

      def nsd_config
        @nsd_config ||= Chef::Resource::Template.new('/etc/nsd/nsd.conf', run_context).tap do |r|
          r.source 'nsd.conf.erb'
          r.cookbook 'nsd'
          r.variables nsd_config_variables
        end
      end

      def nsd_config_variables
        {
          'zones' => repo_zones,
          'keys' => rndc_keys,
          'server_options' => new_resource.server_options.merge(
            'zonesdir' => new_resource.release_path
          ),
          'remote_controls' => new_resource.remote_controls,
          'patterns' => new_resource.patterns
        }
      end

      def repo_zones
        zones = []

        if ::File.directory?(new_resource.release_path)

          Dir.entries(new_resource.release_path).each do |d|
            path = ::File.join(new_resource.release_path, d)

            if ::File.directory?(path)
              options_key = d
              zone_options = new_resource.zone_options[options_key] || {}

              Dir.chdir(new_resource.release_path)
              Dir.entries(path).each do |zone|

                if ::File.extname(zone) == '.zone'
                  zones << {
                    'name' => ::File.basename(zone, '.zone'),
                    'zonefile' => ::File.join(d, zone)
                  }.merge(zone_options)
                end
              end
            end
          end
        end
        zones
      end

      def git_provider
        @git_provider ||= git_repo.provider_for_action(:nothing)
      end

      def git_repo
        @git_repo ||= Chef::Resource::Git.new(new_resource.name, run_context).tap do |r|
          r.repository new_resource.git_repo
          r.branch new_resource.git_branch
          r.destination new_resource.release_path
        end
      end

      def rndc_keys
        return @rndc_keys unless @rndc_keys.nil?
        @rndc_keys = []
        keys_resource = RndcKeysHelper.new(
          new_resource.rndc_keys_data_bag,
          new_resource.rndc_keys_data_bag_item,
        )
        new_resource.rndc_key_names.each do |k|
          @rndc_keys << {
            'name' => k,
            'secret' => keys_resource.get_or_create(k)
          }
        end

        @rndc_keys
      end

      def create_release_path
        Chef::Resource::Directory.new(::File.dirname(new_resource.release_path), run_context).tap do |r|
          r.recursive true
        end.run_action(:create_if_missing)
      end
    end
  end
end
