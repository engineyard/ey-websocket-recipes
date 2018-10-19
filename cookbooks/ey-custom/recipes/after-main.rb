# Comment this out if you don't wish to use env vars for configuration
include_recipe 'custom-env_vars'

include_recipe 'custom-redis'
include_recipe 'custom-websocket'
