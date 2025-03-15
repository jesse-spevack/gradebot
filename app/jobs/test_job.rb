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
      queue_db = ActiveRecord::Base.configurations.configs_for(env_name: Rails.env, name: "queue")
      if queue_db
        Rails.logger.info "Queue database path: #{queue_db.database}"
        # Attempt to verify connection to queue database
        ActiveRecord::Base.establish_connection(
          Rails.application.config.database_configuration["production"]["queue"]
        )
        tables = ActiveRecord::Base.connection.tables
        puts "Tables (#{tables.count}): #{tables.join(', ')}"

        # Check if your Solid Queue tables exist
        required_tables = [
          "solid_queue_processes", "solid_queue_ready_executions",
          "solid_queue_scheduled_executions", "solid_queue_claimed_executions",
          "solid_queue_failed_executions", "solid_queue_semaphores"
        ]

        missing_tables = required_tables - tables
        if missing_tables.any?
          puts "WARNING: Missing required tables: #{missing_tables.join(', ')}"
        else
          puts "All required Solid Queue tables present"
          # Run your other queries here
        end
      else
        Rails.logger.info "No separate queue database configuration found"
      end
    rescue => e
      Rails.logger.error "Error connecting to queue database: #{e.message}"
    end

    Rails.logger.info "=== TEST JOB COMPLETED ==="
  end
end
