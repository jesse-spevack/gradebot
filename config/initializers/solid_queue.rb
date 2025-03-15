# Load SolidQueue configuration
require "yaml"
require "erb"

# Load the queue configuration from queue.yml
queue_config_path = Rails.root.join("config", "queue.yml")
if File.exist?(queue_config_path)
  queue_config = YAML.load(ERB.new(File.read(queue_config_path)).result)[Rails.env]
  
  # Set the configuration
  if defined?(Rails.configuration.solid_queue)
    # Set workers configuration
    if queue_config && queue_config["workers"]
      Rails.configuration.solid_queue.workers_config = queue_config["workers"]
      Rails.logger.info "Loaded #{queue_config["workers"].size} worker configurations from queue.yml"
    end

    # Set dispatcher configuration
    if queue_config && queue_config["dispatchers"]
      Rails.configuration.solid_queue.dispatchers_config = queue_config["dispatchers"]
      Rails.logger.info "Loaded #{queue_config["dispatchers"].size} dispatcher configurations from queue.yml"
    end
  else
    Rails.logger.warn "solid_queue not initialized in Rails configuration"
  end
else
  Rails.logger.warn "No queue.yml configuration file found at #{queue_config_path}"
end