# frozen_string_literal: true

namespace :solid_queue do
  desc "Show status of Solid Queue processing"
  task status: :environment do
    require "solid_queue/process"
    require "solid_queue/ready_execution"
    require "solid_queue/scheduled_execution"
    require "solid_queue/semaphore"
    
    puts "=== SOLID QUEUE STATUS ==="
    puts "Environment: #{Rails.env}"
    
    # Check active processes
    processes = SolidQueue::Process.all
    puts "\nActive Processes (#{processes.count}):"
    if processes.any?
      processes.each do |process|
        puts "  ID: #{process.id}, Kind: #{process.kind}, PID: #{process.pid}, Host: #{process.hostname}"
        puts "  Last heartbeat: #{process.last_heartbeat_at}, Created: #{process.created_at}"
        puts "  ---"
      end
    else
      puts "  No active processes found"
    end
    
    # Check ready executions
    ready = SolidQueue::ReadyExecution.count
    puts "\nReady Executions: #{ready}"
    
    # Check scheduled executions
    scheduled = SolidQueue::ScheduledExecution.count
    puts "Scheduled Executions: #{scheduled}"
    
    # Check claimed executions
    claimed = ActiveRecord::Base.connection.exec_query("SELECT COUNT(*) FROM solid_queue_claimed_executions").first["COUNT(*)"]
    puts "Claimed Executions: #{claimed}"
    
    # Check failed executions
    failed = ActiveRecord::Base.connection.exec_query("SELECT COUNT(*) FROM solid_queue_failed_executions").first["COUNT(*)"]
    puts "Failed Executions: #{failed}"
    
    # Check semaphores
    semaphores = SolidQueue::Semaphore.count
    puts "Active Semaphores: #{semaphores}"
    
    # Database info
    db_config = ActiveRecord::Base.connection_db_config.configuration_hash
    puts "\nDatabase Configuration:"
    puts "  Adapter: #{db_config[:adapter]}"
    puts "  Database: #{db_config[:database]}"
    
    # Queue database info if separate
    begin
      queue_db = ActiveRecord::Base.configurations.configs_for(env_name: Rails.env, name: 'queue')
      if queue_db
        puts "\nQueue Database:"
        puts "  Path: #{queue_db.database}"
        puts "  Exists: #{File.exist?(queue_db.database)}"
        if File.exist?(queue_db.database)
          puts "  Size: #{File.size(queue_db.database)} bytes"
          puts "  Permissions: #{File.stat(queue_db.database).mode.to_s(8)}"
        end
      end
    rescue => e
      puts "Error accessing queue database info: #{e.message}"
    end
    
    puts "\n=== END STATUS ==="
  end
end