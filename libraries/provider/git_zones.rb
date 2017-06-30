class ChefNsd
  class Provider
    class GitZones < Chef::Provider
      include Chef::Mixin::Which
      include Chef::Mixin::ShellOut
      include NsdResourceHelper

      provides :nsd_git_zones, os: "linux"

      def load_current_resource
        @current_resource = ChefNsd::Resource::GitZones.new(new_resource.name)

        current_resource.exists(::File.directory?(new_resource.release_path))
        if current_resource.exists
          current_resource.revision(git_provider.find_current_revision)
        else
          current_resource.revision(nil)
        end

        current_resource
      end

      def action_deploy
        create_release_path
        git_repo.run_action(:sync)

        deployed_revision = git_provider.find_current_revision
        git_diff = git_provider.git_diff(current_resource.revision, deployed_revision)

        begin
          ## get and validate zones. raise if validation fails
          zones = repo_zones(git_diff)

          converge_by("Create nsd zone config: #{new_resource}") do
            nsd_zone_config.content ConfigGenerator.generate_from_hash('zone' => zones)
            nsd_zone_config.run_action(:create)
          end if current_resource.revision.nil? || !git_diff.empty?

        rescue
          Chef::Log.error("Zone validation failed")

          if !current_resource.revision.nil?
            Chef::Log.info("Resetting to #{current_resource.revision}")

            new_resource.updated_by_last_action(false)
            git_repo.revision(current_resource.revision)
            git_provider.git_reset
          else

            Chef::Log.warn("Could not find previous revision to restore")
          end
        end
      end


      private

      def nsd_zone_config
        @nsd_zone_config ||= Chef::Resource::File.new(new_resource.path, run_context).tap do |r|
          r.path new_resource.path
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
