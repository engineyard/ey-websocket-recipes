default['websocket'].tap do |websocket|
  websocket['port'] = 28080

  # This ***must*** be set as the name of the application (as it appears on the
  # server) that you want to expose via websockets. For an easier explanation, 
  # it is whatever comes after /data when you `cd` to your deployment.
  websocket['app'] = 'YOUR_APP_NAME'

  # What's the name of the utility instance on which you want to run the
  # websocket server?
  websocket['utility_name'] = 'websocket'

  # Set up the mountpoint for the websocket connection. This is the path that
  # remote clients will use to initiate a connection. For ActionCable, this is
  # most typically "/cable"
  websocket['mountpoint'] = '/cable'

  websocket['is_websocket_instance'] = node['dna']['instance_role'] == 'util' &&
    node['dna']['name'] == websocket['utility_name']

  # If using ActionCable, you can configure the channel prefix here.
  # websocket['channel'] = "myapp_production"

  # If desired, you can also configure the specific database to use in the Redis
  # server.
  # websocket['database'] = 15
end
