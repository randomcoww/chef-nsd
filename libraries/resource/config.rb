class ChefNsd
  class Resource
    class Config < Chef::Resource
      include NsdResourceHelper

      resource_name :nsd_config

      default_action :create
      allowed_actions :create, :delete

      property :config, Hash
      property :content, [String,NilClass], default: lazy { to_conf }
      property :path, String, desired_state: false,
                              default: lazy { NsdHelper::CONFIG_PATH }

      private

      def to_conf
        ConfigGenerator.generate_from_hash(config)
      end
    end
  end
end
