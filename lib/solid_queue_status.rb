# frozen_string_literal: true

# Utility to check Solid Queue status
module SolidQueueStatus
  def self.check
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
        
        # Try connecting to queue database
        puts "\nChecking queue database connection:"
        ActiveRecord::Base.connected_to(database: :queue) do
          begin
            tables = ActiveRecord::Base.connection.tables
            puts "  Connected successfully"
            puts "  Tables (#{tables.count}): #{tables.join(', ')}"
            
            # Check SQLite journal mode
            begin
              journal_mode = ActiveRecord::Base.connection.execute("PRAGMA journal_mode").first["journal_mode"]
              puts "  Journal mode: #{journal_mode}"
            rescue => e
              puts "  Error checking journal mode: #{e.message}"
            end
          rescue => e
            puts "  Connection error: #{e.message}"
          end
        end
      end
    rescue => e
      puts "Error accessing queue database info: #{e.message}"
    end
    
    puts "\n=== END STATUS ==="
  end
  
  def self.list_jobs
    puts "=== PENDING JOBS ==="
    ActiveRecord::Base.connected_to(database: :queue) do
      puts "Ready jobs: #{SolidQueue::ReadyExecution.count}"
      
      puts "\nReady job details:"
      SolidQueue::ReadyExecution.includes(:job).each do |execution|
        puts "  ID: #{execution.id}, Job ID: #{execution.job_id}"
        puts "  Class: #{execution.job.class_name}"
        puts "  Arguments: #{execution.job.arguments}"
        puts "  Created at: #{execution.created_at}"
        puts "  ---"
      end
    end
  end
  
  def self.check_locks
    puts "=== DATABASE LOCK STATUS ==="
    ActiveRecord::Base.connected_to(database: :queue) do
      begin
        # Set SQLite busy timeout to 10 seconds
        ActiveRecord::Base.connection.execute("PRAGMA busy_timeout = 10000")
        
        # Check journal mode
        result = ActiveRecord::Base.connection.execute("PRAGMA journal_mode")
        puts "Journal mode: #{result.first['journal_mode']}"
        
        # Check for locking issues
        begin
          result = ActiveRecord::Base.connection.execute("PRAGMA lock_status")
          puts "Lock status: #{result.to_a.inspect}"
        rescue => e
          puts "Error checking locks: #{e.message}"
        end
        
        # Check integrity
        begin
          result = ActiveRecord::Base.connection.execute("PRAGMA integrity_check")
          puts "Integrity check: #{result.first['integrity_check']}"
        rescue => e
          puts "Error checking integrity: #{e.message}"
        end
      rescue => e
        puts "Error: #{e.message}"
      end
    end
  end
  
  def self.set_wal_mode
    puts "=== SETTING WAL MODE ==="
    ActiveRecord::Base.connected_to(database: :queue) do
      begin
        ActiveRecord::Base.connection.execute("PRAGMA journal_mode = WAL")
        result = ActiveRecord::Base.connection.execute("PRAGMA journal_mode")
        puts "Journal mode set to: #{result.first['journal_mode']}"
      rescue => e
        puts "Error setting WAL mode: #{e.message}"
      end
    end
  end
end