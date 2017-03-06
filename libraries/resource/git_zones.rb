class ChefNsd
  class Resource
    class GitZones < Chef::Resource
      resource_name :nsd_git_zones

      default_action :deploy
      allowed_actions :deploy, :rollback

      property :release_path, String
      property :git_repo, String
      property :git_branch, String
      property :zone_options, Hash

      property :path, String
    end
  end
end
