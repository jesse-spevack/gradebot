require "capybara/rails"

# Configure Capybara for system tests
Capybara.configure do |config|
  # Disable verbose logging in tests
  config.server = :puma, { Silent: true, stdout: File::NULL, stderr: File::NULL }

  # Don't show Capybara starting/stopping server messages
  config.server_host = "127.0.0.1"
  config.server_port = nil # Use a random available port

  # Reduce default wait time for faster tests
  config.default_max_wait_time = 2
end

# Suppress noisy Puma output
Capybara.register_server :puma do |app, port, host, options|
  require "rack/handler/puma"

  # Configure Puma with quiet mode
  puma_options = {
    Silent: true,
    Host: host,
    Port: port,
    Threads: "0:4",
    workers: 0,
    daemon: false,
    log_requests: false
  }

  Rack::Handler::Puma.run(app, **puma_options)
end
