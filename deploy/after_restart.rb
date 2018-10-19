if config.current_name.to_s == 'websocket'
  sudo "monit -g websocket_#{config.app} start"
end
