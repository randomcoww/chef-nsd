class Chef
  class Resource
    class Nsd < Chef::Resource
      resource_name :nsd

      default_action :deploy
      allowed_actions :deploy, :rollback

      property :release_path, String
      property :git_repo, String
      property :git_branch, String

      property :rndc_keys_data_bag, String
      property :rndc_keys_data_bag_item, String
      property :rndc_key_names, Array

      property :server_options, Hash
      property :remote_controls, Array
      property :patterns, Array
      property :zone_options, Hash
    end
  end
end
