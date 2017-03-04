class Chef
  class Provider
    class Nsd < Chef::Provider
      include Dbag
      include Chef::Mixin::Which
      include Chef::Mixin::ShellOut

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
          deployed_revision = git_provider.find_current_revision
          git_diff = git_provider.git_diff(current_revision, deployed_revision)

          begin
            zones = repo_zones(git_diff)

          rescue
            Chef::Log.info("Zone validation failed. Resetting to #{current_revision}")

            git_repo.revision(current_revision)
            git_provider.git_reset

            zones = repo_zones
          end

          nsd_config.variables({
            'server_options' => new_resource.server_options.merge(
              'zonesdir' => new_resource.release_path
            ),
            'config_categories' => {
              'zone' => zones,
              'key' => rndc_keys,
              'remote-control' => new_resource.remote_controls,
              'pattern' => new_resource.patterns
            }
          })

          nsd_config.run_action(:create)

          reload_service
        end
      end


      private

      def reload_service
        nsd_service.run_action(:start)

        if nsd_config.updated_by_last_action?
          nsd_service.run_action(:restart)
        end

        if git_repo.updated_by_last_action?
          nsd_service.run_action(:reload)
        end
      end

      def nsd_service
        @nsd_service ||= Chef::Resource::Service.new('nsd', run_context).tap do |r|
          r.provider Chef::Provider::Service::Systemd
        end
      end

      def nsd_config
        @nsd_config ||= Chef::Resource::Template.new('/etc/nsd/nsd.conf', run_context).tap do |r|
          r.source 'nsd.conf.erb'
          r.cookbook 'nsd'
        end
      end

      def repo_zones(git_diff=nil)
        ## check which zones updated for validation
        files_updated = {}
        if !git_diff.nil?
          git_diff.each_line do |e|
            files_updated[e.chomp] = true
          end
        end

        zones = []

        if ::File.directory?(new_resource.release_path)

          Dir.entries(new_resource.release_path).each do |d|
            path = ::File.join(new_resource.release_path, d)

            if ::File.directory?(path)
              zone_options = new_resource.zone_options[d] || {}

              Dir.chdir(new_resource.release_path)
              Dir.entries(path).each do |zone|

                if ::File.extname(zone) == '.zone'
                  name = ::File.basename(zone, '.zone')
                  zonefile = ::File.join(d, zone)

                  if files_updated.has_key?(zonefile)
                    Chef::Log.info("Validate updated zonefile #{zonefile}")
                    nsd_checkzone(name, zonefile)
                  end

                  zones << {
                    'name' => name,
                    'zonefile' => zonefile
                  }.merge(zone_options)
                end
              end
            end
          end
        end
        zones
      end

      def rndc_keys
        return @rndc_keys unless @rndc_keys.nil?
        @rndc_keys = []
        keys_resource = Dbag::RndcKey.new(
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

      def nsd_checkzone(zone, zonefile)
        shell_out!("#{nsd_checkzone_path} #{zone} #{zonefile}")
      end

      def nsd_checkzone_path
        @nsd_checkzone_path ||= which('nsd-checkzone')
      end
    end
  end
end
