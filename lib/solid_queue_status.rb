# frozen_string_literal: true

# Utility to check Solid Queue status
module SolidQueueStatus
  def self.check
    puts "=== SOLID QUEUE STATUS ==="
    puts "Environment: #{Rails.env}"
    
    # Check if solid_queue is loaded and tables exist
    begin
      require "solid_queue"

      # Database info
      db_config = ActiveRecord::Base.connection_db_config.configuration_hash
      puts "\nPrimary Database Configuration:"
      puts "  Adapter: #{db_config[:adapter]}"
      puts "  Database: #{db_config[:database]}"
      
      # Queue database info if separate
      queue_db = ActiveRecord::Base.configurations.configs_for(env_name: Rails.env, name: "queue")
      if queue_db
        puts "\nQueue Database Configuration:"
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
            
            # Check if necessary tables exist
            required_tables = [
              "solid_queue_processes", "solid_queue_ready_executions", 
              "solid_queue_scheduled_executions", "solid_queue_claimed_executions",
              "solid_queue_failed_executions", "solid_queue_semaphores"
            ]
            
            missing_tables = required_tables - tables
            if missing_tables.any?
              puts "  WARNING: Missing required tables: #{missing_tables.join(', ')}"
              puts "  Run bin/rails db:schema:load:queue RAILS_ENV=production to create missing tables"
            else
              # All required tables exist, check counts
              process_count = table_count("solid_queue_processes")
              puts "\nActive Processes: #{process_count}"
              
              if process_count > 0
                puts "\nProcess details:"
                process_records = exec_query("SELECT * FROM solid_queue_processes")
                process_records.each do |process|
                  puts "  ID: #{process['id']}, Kind: #{process['kind']}, PID: #{process['pid']}, Host: #{process['hostname']}"
                  puts "  Last heartbeat: #{process['last_heartbeat_at']}, Created: #{process['created_at']}"
                  puts "  ---"
                end
              end
              
              # Check executions
              puts "\nReady Executions: #{table_count('solid_queue_ready_executions')}"
              puts "Scheduled Executions: #{table_count('solid_queue_scheduled_executions')}"
              puts "Claimed Executions: #{table_count('solid_queue_claimed_executions')}"
              puts "Failed Executions: #{table_count('solid_queue_failed_executions')}"
              puts "Active Semaphores: #{table_count('solid_queue_semaphores')}"
              
              # Check SQLite journal mode
              begin
                journal_mode = ActiveRecord::Base.connection.execute("PRAGMA journal_mode").first["journal_mode"]
                puts "\nJournal mode: #{journal_mode}"
                puts "  Recommendation: If you're having concurrency issues, consider switching to WAL mode"
                puts "  with SolidQueueStatus.set_wal_mode" if journal_mode != "wal"
              rescue => e
                puts "\nError checking journal mode: #{e.message}"
              end
            end
          rescue => e
            puts "  Connection error: #{e.message}"
          end
        end
      else
        puts "\nNo separate queue database configuration found"
        puts "Using primary database for job processing"
        
        # Check if tables exist in primary database
        tables = ActiveRecord::Base.connection.tables
        solid_queue_tables = tables.select { |t| t.start_with?("solid_queue_") }
        
        if solid_queue_tables.empty?
          puts "\nWARNING: No Solid Queue tables found in primary database"
          puts "Run bin/rails db:schema:load to create missing tables"
        else
          puts "\nSolid Queue tables in primary database:"
          puts "  #{solid_queue_tables.join(', ')}"
          
          # Check process count in primary database
          process_count = table_count("solid_queue_processes")
          puts "\nActive Processes: #{process_count}"
        end
      end
    rescue LoadError => e
      puts "\nERROR: Could not load solid_queue: #{e.message}"
      puts "Make sure the solid_queue gem is installed and properly configured."
    rescue => e
      puts "\nERROR: #{e.message}"
    end
    
    puts "\n=== END STATUS ==="
  end
  
  def self.list_jobs
    puts "=== PENDING JOBS ==="
    
    begin
      # Determine which database to use
      queue_db = ActiveRecord::Base.configurations.configs_for(env_name: Rails.env, name: "queue")
      database = queue_db ? :queue : :primary
      
      ActiveRecord::Base.connected_to(database: database) do
        begin
          # Check if table exists
          tables = ActiveRecord::Base.connection.tables
          unless tables.include?("solid_queue_ready_executions")
            puts "ERROR: solid_queue_ready_executions table does not exist"
            return
          end
          
          ready_count = table_count("solid_queue_ready_executions")
          puts "Ready jobs: #{ready_count}"
          
          if ready_count > 0
            puts "\nReady job details:"
            # Join with jobs table to get details
            if tables.include?("solid_queue_jobs")
              jobs = exec_query(<<~SQL)
                SELECT r.id, r.job_id, j.class_name, j.arguments, r.created_at
                FROM solid_queue_ready_executions r
                JOIN solid_queue_jobs j ON r.job_id = j.id
              SQL
              
              jobs.each do |job|
                puts "  ID: #{job['id']}, Job ID: #{job['job_id']}"
                puts "  Class: #{job['class_name']}"
                puts "  Arguments: #{job['arguments']}"
                puts "  Created at: #{job['created_at']}"
                puts "  ---"
              end
            else
              # Just show ready executions if jobs table missing
              execs = exec_query("SELECT * FROM solid_queue_ready_executions")
              execs.each do |exec|
                puts "  ID: #{exec['id']}, Job ID: #{exec['job_id']}"
                puts "  Created at: #{exec['created_at']}"
                puts "  ---"
              end
            end
          end
        rescue => e
          puts "Error listing jobs: #{e.message}"
        end
      end
    rescue => e
      puts "Database connection error: #{e.message}"
    end
  end
  
  def self.check_locks
    puts "=== DATABASE LOCK STATUS ==="
    
    begin
      # Determine which database to use
      queue_db = ActiveRecord::Base.configurations.configs_for(env_name: Rails.env, name: "queue")
      database = queue_db ? :queue : :primary
      
      ActiveRecord::Base.connected_to(database: database) do
        begin
          # Set SQLite busy timeout to 10 seconds
          ActiveRecord::Base.connection.execute("PRAGMA busy_timeout = 10000")
          puts "Set busy timeout to 10000ms"
          
          # Check journal mode
          result = ActiveRecord::Base.connection.execute("PRAGMA journal_mode")
          journal_mode = result.first["journal_mode"]
          puts "Journal mode: #{journal_mode}"
          
          if journal_mode != "wal"
            puts "  WARNING: Not using WAL mode. This can cause locking issues with concurrent access."
            puts "  Consider switching to WAL mode with SolidQueueStatus.set_wal_mode"
          end
          
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
            integrity = result.first["integrity_check"]
            puts "Integrity check: #{integrity}"
            
            if integrity != "ok"
              puts "  WARNING: Database integrity check failed. Database may be corrupted."
            end
          rescue => e
            puts "Error checking integrity: #{e.message}"
          end
          
          # Check if database is writable
          begin
            ActiveRecord::Base.connection.execute("BEGIN IMMEDIATE TRANSACTION")
            ActiveRecord::Base.connection.execute("ROLLBACK")
            puts "Database is writable: Yes"
          rescue => e
            puts "Database is writable: No"
            puts "  Error: #{e.message}"
          end
        rescue => e
          puts "Error: #{e.message}"
        end
      end
    rescue => e
      puts "Database connection error: #{e.message}"
    end
  end
  
  def self.set_wal_mode
    puts "=== SETTING WAL MODE ==="
    
    begin
      # Determine which database to use
      queue_db = ActiveRecord::Base.configurations.configs_for(env_name: Rails.env, name: "queue")
      database = queue_db ? :queue : :primary
      
      ActiveRecord::Base.connected_to(database: database) do
        begin
          # Check current mode
          old_mode = ActiveRecord::Base.connection.execute("PRAGMA journal_mode").first["journal_mode"]
          puts "Current journal mode: #{old_mode}"
          
          # Set to WAL mode
          result = ActiveRecord::Base.connection.execute("PRAGMA journal_mode = WAL")
          new_mode = result.first["journal_mode"]
          
          if new_mode.downcase == "wal"
            puts "Journal mode successfully set to: #{new_mode}"
            puts "This should improve concurrency for SQLite database access."
          else
            puts "WARNING: Failed to set journal mode to WAL. Current mode: #{new_mode}"
            puts "Check database permissions and file system support for WAL mode."
          end
        rescue => e
          puts "Error setting WAL mode: #{e.message}"
        end
      end
    rescue => e
      puts "Database connection error: #{e.message}"
    end
  end
  
  def self.initialize_tables
    puts "=== INITIALIZING SOLID QUEUE TABLES ==="
    
    begin
      require "solid_queue"
      
      # Determine which database to use
      queue_db = ActiveRecord::Base.configurations.configs_for(env_name: Rails.env, name: "queue")
      database = queue_db ? :queue : :primary
      
      ActiveRecord::Base.connected_to(database: database) do
        begin
          # Check if tables exist
          tables = ActiveRecord::Base.connection.tables
          solid_queue_tables = tables.select { |t| t.start_with?("solid_queue_") }
          
          if solid_queue_tables.empty?
            puts "No Solid Queue tables found in database, creating tables..."
            
            # Required tables for Solid Queue
            create_tables = [
              # Processes table
              <<~SQL,
                CREATE TABLE IF NOT EXISTS solid_queue_processes (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  kind TEXT NOT NULL,
                  pid INTEGER NOT NULL,
                  hostname TEXT NOT NULL,
                  created_at TIMESTAMP NOT NULL,
                  last_heartbeat_at TIMESTAMP NOT NULL
                )
              SQL
              
              # Jobs table
              <<~SQL,
                CREATE TABLE IF NOT EXISTS solid_queue_jobs (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  class_name TEXT NOT NULL,
                  arguments TEXT NOT NULL,
                  priority INTEGER DEFAULT 0 NOT NULL,
                  queue_name TEXT NOT NULL,
                  created_at TIMESTAMP NOT NULL
                )
              SQL
              
              # Ready executions
              <<~SQL,
                CREATE TABLE IF NOT EXISTS solid_queue_ready_executions (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  job_id INTEGER NOT NULL,
                  queue_name TEXT NOT NULL,
                  priority INTEGER DEFAULT 0 NOT NULL,
                  created_at TIMESTAMP NOT NULL,
                  CONSTRAINT fk_job FOREIGN KEY (job_id) REFERENCES solid_queue_jobs(id) ON DELETE CASCADE
                )
              SQL
              
              # Scheduled executions
              <<~SQL,
                CREATE TABLE IF NOT EXISTS solid_queue_scheduled_executions (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  job_id INTEGER NOT NULL,
                  queue_name TEXT NOT NULL,
                  priority INTEGER DEFAULT 0 NOT NULL,
                  scheduled_at TIMESTAMP NOT NULL,
                  created_at TIMESTAMP NOT NULL,
                  CONSTRAINT fk_job FOREIGN KEY (job_id) REFERENCES solid_queue_jobs(id) ON DELETE CASCADE
                )
              SQL
              
              # Claimed executions
              <<~SQL,
                CREATE TABLE IF NOT EXISTS solid_queue_claimed_executions (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  job_id INTEGER NOT NULL,
                  process_id INTEGER NOT NULL,
                  created_at TIMESTAMP NOT NULL,
                  CONSTRAINT fk_job FOREIGN KEY (job_id) REFERENCES solid_queue_jobs(id) ON DELETE CASCADE,
                  CONSTRAINT fk_process FOREIGN KEY (process_id) REFERENCES solid_queue_processes(id) ON DELETE CASCADE
                )
              SQL
              
              # Failed executions
              <<~SQL,
                CREATE TABLE IF NOT EXISTS solid_queue_failed_executions (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  job_id INTEGER NOT NULL,
                  error TEXT NOT NULL,
                  created_at TIMESTAMP NOT NULL,
                  CONSTRAINT fk_job FOREIGN KEY (job_id) REFERENCES solid_queue_jobs(id) ON DELETE CASCADE
                )
              SQL
              
              # Semaphores
              <<~SQL,
                CREATE TABLE IF NOT EXISTS solid_queue_semaphores (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  key TEXT NOT NULL UNIQUE,
                  value INTEGER DEFAULT 1 NOT NULL,
                  expires_at TIMESTAMP NULL,
                  created_at TIMESTAMP NOT NULL,
                  updated_at TIMESTAMP NOT NULL
                )
              SQL
              
              # Create indexes
              <<~SQL,
                CREATE INDEX IF NOT EXISTS index_solid_queue_ready_executions_for_polling 
                ON solid_queue_ready_executions (queue_name, priority, created_at)
              SQL
              <<~SQL,
                CREATE INDEX IF NOT EXISTS index_solid_queue_scheduled_executions_for_polling 
                ON solid_queue_scheduled_executions (scheduled_at)
              SQL
            ]
            
            # Execute all create table statements
            create_tables.each do |sql|
              begin
                ActiveRecord::Base.connection.execute(sql)
                puts "Created table: #{sql.split("\n").first}"
              rescue => e
                puts "Error creating table: #{e.message}"
              end
            end
            
            puts "\nSolid Queue tables created successfully"
            puts "Note: This is a basic initialization and may not include all the latest schema changes"
            puts "For production, consider running proper migrations via:"
            puts "bin/rails db:schema:load:queue RAILS_ENV=production"
          else
            puts "Solid Queue tables already exist (#{solid_queue_tables.count} tables)"
            puts solid_queue_tables.join(", ")
          end
        rescue => e
          puts "Error initializing tables: #{e.message}"
        end
      end
    rescue LoadError => e
      puts "Could not load solid_queue: #{e.message}"
    rescue => e
      puts "Error: #{e.message}"
    end
  end
  
  def self.check_migrations
    puts "=== CHECKING MIGRATIONS ==="
    
    # Check schema versions
    begin
      # Check primary schema version
      schema_version = ActiveRecord::Base.connection.migration_context.current_version
      puts "Primary database schema version: #{schema_version}"
      
      # Check if queue database exists and its schema version
      queue_db = ActiveRecord::Base.configurations.configs_for(env_name: Rails.env, name: "queue")
      if queue_db
        puts "\nQueue database configuration found:"
        puts "  Path: #{queue_db.database}"
        
        if File.exist?(queue_db.database)
          ActiveRecord::Base.connected_to(database: :queue) do
            begin
              # Check if the schema_migrations table exists
              tables = ActiveRecord::Base.connection.tables
              if tables.include?("schema_migrations")
                # Get the latest migration version
                query = "SELECT version FROM schema_migrations ORDER BY version DESC LIMIT 1"
                result = ActiveRecord::Base.connection.execute(query)
                if result.present?
                  version = result.first["version"]
                  puts "  Queue database schema version: #{version}"
                else
                  puts "  Queue database schema version: No migrations found"
                end
              else
                puts "  WARNING: schema_migrations table not found in queue database"
                puts "  Database may not be properly initialized"
              end
            rescue => e
              puts "  Error checking queue database schema: #{e.message}"
            end
          end
        else
          puts "  WARNING: Queue database file does not exist: #{queue_db.database}"
        end
      else
        puts "\nNo separate queue database configuration found"
      end
    rescue => e
      puts "Error checking migrations: #{e.message}"
    end
  end
  
  private
  
  def self.table_count(table_name)
    result = exec_query("SELECT COUNT(*) as count FROM #{table_name}")
    result.first["count"]
  rescue => e
    "Error: #{e.message}"
  end
  
  def self.exec_query(sql)
    ActiveRecord::Base.connection.execute(sql)
  end
end