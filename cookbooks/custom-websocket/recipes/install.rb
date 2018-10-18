#
# Cookbook Name: custom-websocket
# Recipe: install
#

# Set up the actual server on the websocket instance
if node['websocket']['is_websocket_instance']
  ey_cloud_report 'custom-websocket' do
    message 'installing custom-websocket'
  end

  app = node['websocket']['app']
  port = node['websocket']['port']
  ssh_username = node['owner']
  framework_env = node['dna']['engineyard']['environment']['framework_env']
  env_name = node['dna']['engineyard']['environment']['name']
  restart_resource = "restart-websocket-#{app}"

  directory "/var/run/engineyard/#{app}" do
    owner 'deploy'
    group 'deploy'
    mode 0755
    recursive true
  end

  template "/data/#{app}/shared/config/env.websocket" do
    source 'env.websocket.erb'
    backup 0
    owner 'deploy'
    group 'deploy'
    mode 0755
    variables(
      {
        'app' => app,
        'environment' => framework_env,

      }
    )
  end

  # Install a rackup config for the websocket server. Generally speaking, the
  # application will already have one of these, but just in case ...
  template "/data/#{app}/shared/config/websocket.ru" do
    source 'websocket.ru.erb'
    backup 0
    owner 'deploy'
    group 'deploy'
    mode 0755
    variables(
      {
        'app' => app,
      }
    )
  end

  template "/engineyard/bin/websocket_#{app}" do
    source 'websocket.sh.erb'
    owner 'deploy'
    group 'deploy'
    mode 0755
    backup 0
    variables(
      {
        'app' => app,
        'port' => port,
      }
    )
  end

  template "/etc/monit.d/websocket_#{app}.monitrc" do
    source 'websocket.monitrc.erb'
    owner 'root'
    group 'root'
    mode 0644
    backup 0
    variables(
      {
        'app' => app,
        'port' => port,
      }
    )
  end

  execute restart_resource do
    command "monit restart websocket_#{app}"
    action :nothing
  end
end
