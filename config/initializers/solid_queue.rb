# Load SolidQueue configuration
require "yaml"
require "erb"

# First set up database connection based on environment config
if defined?(Rails.configuration.solid_queue) && Rails.configuration.solid_queue.is_a?(Hash)
  Rails.logger.info "Using SolidQueue configuration from environment: #{Rails.configuration.solid_queue.inspect}"
end

# Then load the worker configuration from queue.yml
queue_config_path = Rails.root.join("config", "queue.yml")
if File.exist?(queue_config_path)
  begin
    queue_config = YAML.safe_load(ERB.new(File.read(queue_config_path)).result, aliases: true)[Rails.env]
    
    # Apply the worker configuration if available
    if defined?(Rails.application.config.solid_queue)
      # Merge with any existing config (configured in production.rb)
      config = Rails.application.config.solid_queue
      
      # Convert to hash if it's not already
      config = {} unless config.is_a?(Hash)
      
      # Add worker configuration
      if queue_config && queue_config["workers"]
        config[:workers] = queue_config["workers"]
        Rails.logger.info "Loaded #{queue_config["workers"].size} worker configurations from queue.yml"
      end
      
      # Add dispatcher configuration
      if queue_config && queue_config["dispatchers"]
        config[:dispatchers] = queue_config["dispatchers"]
        Rails.logger.info "Loaded #{queue_config["dispatchers"].size} dispatcher configurations from queue.yml"
      end
      
      # Update the configuration
      Rails.application.config.solid_queue = config
    else
      Rails.logger.warn "solid_queue not initialized in Rails configuration"
    end
  rescue => e
    Rails.logger.error "Error loading queue.yml: #{e.message}"
  end
else
  Rails.logger.warn "No queue.yml configuration file found at #{queue_config_path}"
end