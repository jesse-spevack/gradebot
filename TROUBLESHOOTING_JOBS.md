# Troubleshooting Background Jobs

This guide provides a step-by-step process for diagnosing issues with Solid Queue background job processing in production.

## Step 1: Deploy the latest changes

Ensure you've deployed the latest code changes with enhanced logging:

```bash
bin/kamal deploy
```

## Step 2: Check job container status

Check if the job container is running:

```bash
bin/kamal ps
```

Look for a container with the `cmd: bin/jobs` command. It should be in the "running" state.

## Step 3: Check job container logs

Check the logs from the job container to see initialization info:

```bash
bin/kamal logs -r job
```

Look for these logs which should appear when the job container starts:
- "Starting Solid Queue with Rails env: production"
- "Database config: ..." 
- "Job worker config: ..."
- "Job concurrency: 2"

## Step 4: Check Solid Queue status

Connect to the production console and check the status of Solid Queue:

```bash
bin/kamal console
```

Once in the console, run:

```ruby
load Rails.root.join("lib/tasks/solid_queue.rake")
Rake::Task["solid_queue:status"].invoke
```

This will show:
- Active processes and their details
- Number of ready, scheduled, claimed, and failed executions
- Database configuration information

## Step 5: Check database files

Still in the console, verify the database files:

```ruby
queue_db = ActiveRecord::Base.configurations.configs_for(env_name: Rails.env, name: 'queue')
File.exist?(queue_db.database)
File.stat(queue_db.database).mode.to_s(8)  # Check permissions
```

## Step 6: Enqueue a test job

Test job processing by enqueuing a test job:

```ruby
TestJob.perform_later("test_#{Time.current.to_i}")
```

## Step 7: Check job status

Check if the job was scheduled in the queue:

```ruby
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
```

## Step 8: Monitor job logs

Exit the console and watch the job container logs to see if the test job gets processed:

```bash
bin/kamal logs -f -r job
```

Look for "=== TEST JOB EXECUTED AT ..." which indicates the job was processed.

## Step 9: Check for database locking issues

If jobs aren't processing, check for SQLite database locking issues:

```bash
bin/kamal console
```

```ruby
ActiveRecord::Base.connected_to(database: :queue) do
  begin
    ActiveRecord::Base.connection.execute("PRAGMA busy_timeout = 10000")  # Set timeout to 10 seconds
    result = ActiveRecord::Base.connection.execute("PRAGMA journal_mode")
    puts "Journal mode: #{result.first['journal_mode']}"
    
    # Check for locking issues
    result = ActiveRecord::Base.connection.execute("PRAGMA lock_status")
    puts "Lock status: #{result.to_a.inspect}"
  rescue => e
    puts "Error: #{e.message}"
  end
end
```

## Step 10: Check for file permission issues

If suspecting file permission issues:

```bash
bin/kamal shell
```

```bash
ls -la /rails/storage/
```

Ensure the sqlite database files are readable/writable by the application user.

## Step 11: Restart the job container

If jobs still aren't processing, try restarting the job container:

```bash
bin/kamal restart -r job
```

## Step 12: Database file corruption check

If you suspect database corruption:

```bash
bin/kamal shell
```

```bash
sqlite3 /rails/storage/production_queue.sqlite3 "PRAGMA integrity_check"
```

## Possible Solutions

If you've identified the issue, here are some common solutions:

1. **Database locking**: Change SQLite journal mode to WAL for better concurrency:
   ```ruby
   ActiveRecord::Base.connected_to(database: :queue) do
     ActiveRecord::Base.connection.execute("PRAGMA journal_mode = WAL")
   end
   ```

2. **Permission issues**: Fix permissions on the database files:
   ```bash
   chmod 666 /rails/storage/production_queue.sqlite3
   ```

3. **Database corruption**: If the database is corrupted, you may need to recreate it:
   ```bash
   # Backup first
   cp /rails/storage/production_queue.sqlite3 /rails/storage/production_queue.sqlite3.bak
   
   # Then recreate schema
   bin/rails db:schema:load:queue RAILS_ENV=production
   ```

4. **Consider using PostgreSQL**: For production deployments, consider switching to PostgreSQL for better concurrency handling.

## Advanced Troubleshooting

If the issue persists, consider:

1. Enabling more detailed SQLite logging:
   ```ruby
   ActiveRecord::Base.logger = Logger.new(STDOUT)
   ActiveRecord::Base.logger.level = Logger::DEBUG
   ```

2. Inspecting SolidQueue processes and Workers:
   ```ruby
   SolidQueue::Process.all.each { |p| puts "#{p.id}: #{p.kind} on #{p.hostname}, last heartbeat: #{p.last_heartbeat_at}" }
   ```

3. Checking for deadlocks or stuck processes:
   ```ruby
   old_processes = SolidQueue::Process.where('last_heartbeat_at < ?', 5.minutes.ago)
   old_processes.each { |p| puts "Stale process: #{p.id} (#{p.kind}) last heartbeat: #{p.last_heartbeat_at}" }
   ```