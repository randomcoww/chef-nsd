require 'ipaddr'

class ChefNsd
  class Resource
    class KeaZonefile < Chef::Resource
      include NsdConfigGenerator
      include MysqlConfig

      resource_name :nsd_kea_zonefile

      default_action :create
      allowed_actions :create

      property :domain, String
      property :ttl, Integer, default: 300
      property :name_server, String
      property :email_addr, String
      property :sn, Integer, default: 2017010101
      property :ref, Integer, default: 28800
      property :ret, Integer, default: 14400
      property :ex, Integer, default: 604800
      property :nx, Integer, default: 86400

      property :host, String
      property :database, String
      property :username, String
      property :password, String
      property :timeout, Integer, default: 120

      property :hosts, Hash, default: lazy { get_lease_hosts }
      property :zone_options, Hash, default: {}
      property :path, String, default: lazy { ::File.join(Chef::Config[:file_cache_path], 'nsd', domain) }

      def provider
        ChefNsd::Provider::Zonefile
      end


      private

      def get_lease_hosts
        result = {}

        client = MysqlConfig::Client.new(timeout,
          username: username,
          database: database,
          host: host,
          password: password
        )

        query = %Q{SELECT hostname,address FROM lease4 WHERE client_id IS NOT NULL AND hostname!="" AND state=0 ORDER BY hostname}
        client.query(query).each do |e|
          result[e['hostname'].split('.').first] = IPAddr.new(e['address'], Socket::AF_INET).to_s
        end

        return result
      end
    end
  end
end
