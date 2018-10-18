#
# Cookbook Name: custom-websocket
# Recipe: configure
#

# Find the websocket utility instance. We really can't continue if it's not
# present, so raise an error if it's not found.
websocket_instance = node['dna']['engineyard']['environment']['instances'].
  find {|instance| instance['name'] == node['websocket']['utility_name']}

raise "No websocket instance present" unless websocket_instance

nginx_roles = ['app_master', 'app', 'solo']
application_roles = nginx_roles + ['util']

app = node['websocket']['app']
websocket_hostname = websocket_instance['private_hostname']
websocket_port = node['websocket']['port']

# Set up the app's cable configuration on instances that have the app installed
if application_roles.include? node['dna']['instance_role']
  framework_env = node['dna']['engineyard']['environment']['framework_env']
  database = node['websocket']['database']

  redis_uri = "redis://#{websocket_hostname}:6379"
  redis_uri += "/#{database}" if database

  template "/data/#{app}/shared/config/cable.yml" do
    source 'cable.yml.erb'
    owner 'deploy'
    group 'deploy'
    mode 0644
    backup 0
    variables(
      {
        'environment' => framework_env,
        'url' => redis_uri,
        'channel' => node['websocket']['channel'],
      }
    )
  end
end

# Set up the websocket upstream and location in nginx for app instances
if nginx_roles.include? node['dna']['instance_role']
  # Set up the upstream
  template "/data/nginx/http-custom.conf" do
    source 'upstreams.conf.erb'
    owner 'deploy'
    group 'deploy'
    mode 0644
    backup 0
    variables(
      {
        'app' => app,
        'hostname' => websocket_hostname,
        'port' => websocket_port,
      }
    )
  end

  # Sanitize the websocket mount point
  mountpoint = node['websocket']['mountpoint']
  mountpoint = "/#{mountpoint}" unless mountpoint.match(/^\//)

  # Set up the custom location
  template "/data/nginx/servers/#{app}/custom.conf" do
    source 'custom.conf.erb'
    owner 'deploy'
    group 'deploy'
    mode 0644
    backup 0
    variables(
      {
        'app' => app,
        'mountpoint' => mountpoint,
      }
    )
  end

  # We just added to the nginx configuration, so we need to restart it
  service 'nginx'

  execute 'restart-nginx' do
    notifies :restart, 'service[nginx]', :delayed
    action :nothing
  end
end
