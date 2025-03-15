# frozen_string_literal: true

# Simple job for testing background job processing
class TestJob < ApplicationJob
  queue_as :default

  def perform(*args)
    # Get database connection info
    db_config = ActiveRecord::Base.connection_db_config.configuration_hash
    db_path = db_config[:database]
    
    # Log extensive debugging information
    Rails.logger.info "=== TEST JOB EXECUTED AT #{Time.current} ==="
    Rails.logger.info "Arguments: #{args.inspect}"
    Rails.logger.info "Queue adapter: #{Rails.application.config.active_job.queue_adapter}"
    Rails.logger.info "Database config: #{db_config.inspect}"
    Rails.logger.info "Database exists: #{File.exist?(db_path)}"
    Rails.logger.info "Database permissions: #{File.stat(db_path).mode.to_s(8)}" if File.exist?(db_path)
    Rails.logger.info "Job ID: #{job_id}"
    Rails.logger.info "Queue name: #{queue_name}"
    Rails.logger.info "Process ID: #{Process.pid}"
    Rails.logger.info "Rails env: #{Rails.env}"
    
    # Try to access the queue database directly
    begin
      queue_db = ActiveRecord::Base.configurations.configs_for(env_name: Rails.env, name: 'queue')
      if queue_db
        Rails.logger.info "Queue database path: #{queue_db.database}"
        # Attempt to verify connection to queue database
        result = ActiveRecord::Base.connected_to(database: :queue) do
          ActiveRecord::Base.connection.execute("SELECT COUNT(*) FROM sqlite_master")
        end
        Rails.logger.info "Queue database tables count: #{result.first.first}"
      else
        Rails.logger.info "No separate queue database configuration found"
      end
    rescue => e
      Rails.logger.error "Error connecting to queue database: #{e.message}"
    end
    
    Rails.logger.info "=== TEST JOB COMPLETED ==="
  end
end
