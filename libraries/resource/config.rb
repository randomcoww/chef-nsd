class ChefNsd
  class Resource
    class Config < Chef::Resource
      include ConfigGenerator

      resource_name :nsd_config

      default_action :create
      allowed_actions :create, :delete

      property :exists, [TrueClass, FalseClass]
      property :config, Hash
      property :content, String, default: lazy { to_conf }
      property :path, String, desired_state: false,
                              default: lazy { Nsd::CONFIG_PATH }

      private

      def to_conf
        generate_config(config)
      end
    end
  end
end
