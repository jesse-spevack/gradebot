# Troubleshooting Background Jobs

This guide provides a step-by-step process for diagnosing issues with Solid Queue background job processing in production.

## Step 1: Deploy the latest changes

Ensure you've deployed the latest code changes with enhanced logging:

```bash
bin/kamal deploy
```

### Result:

✅ Done!
```
  INFO [835b6d26] Finished in 6.420 seconds with exit status 0 (successful).
```

## Step 2: Check job container status

Check if the job container is running:

```bash
bin/kamal ps
```

Look for a container with the `cmd: bin/jobs` command. It should be in the "running" state.

### Result:

✅ Done!
```

❯ bin/kamal app exec --interactive "ps"
Get most recent version available as an image...
Launching interactive command with version latest via SSH from new container on 34.44.244.114...
    PID TTY          TIME CMD
      1 pts/0    00:00:00 ps
Connection to 34.44.244.114 closed.
```

And then:

```
❯ kamal app exec -- ps aux

Get most recent version available as an image...
Launching command with version latest from new container...
  INFO [8e07a56b] Running docker run --rm --network kamal --env SOLID_QUEUE_POLLING_INTERVAL="1" --env SOLID_QUEUE_DISPATCHER_BATCH_SIZE="100" --env RAILS_LOG_LEVEL="debug" --env JOB_CONCURRENCY="2" --env-file .kamal/apps/gradebot/env/roles/web.env --log-opt max-size="10m" --volume gradebot_storage:/rails/storage us-docker.pkg.dev/gradebot-451722/repository-1/gradebot:latest ps aux on 34.44.244.114
  INFO [8e07a56b] Finished in 0.988 seconds with exit status 0 (successful).
App Host: 34.44.244.114
USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
rails          1 10.5  0.6  23788 13668 ?        Rs   00:50   0:00 ps aux

  INFO [aed42aec] Running docker run --rm --network kamal --env SOLID_QUEUE_POLLING_INTERVAL="1" --env SOLID_QUEUE_DISPATCHER_BATCH_SIZE="100" --env RAILS_LOG_LEVEL="debug" --env JOB_CONCURRENCY="2" --env-file .kamal/apps/gradebot/env/roles/job.env --log-opt max-size="10m" --volume gradebot_storage:/rails/storage us-docker.pkg.dev/gradebot-451722/repository-1/gradebot:latest ps aux on 34.44.244.114
  INFO [aed42aec] Finished in 0.968 seconds with exit status 0 (successful).
App Host: 34.44.244.114
USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
rails          1 10.2  0.6  23788 13676 ?        Rs   00:50   0:00 ps aux
```


## Step 3: Check job container logs

Check the logs from the job container to see initialization info:

```bash
bin/kamal logs -r job
```

Look for these logs which should appear when the job container starts:


### Result:

✅ Done!

- "Starting Solid Queue with Rails env: production"
```
❯ bin/kamal app logs -r job -g "Starting Solid Queue with Rails env: production"

  INFO [fc3517cb] Running /usr/bin/env sh -c 'docker ps --latest --quiet --filter label=service=gradebot --filter label=destination= --filter label=role=job --filter status=running --filter status=restarting --filter ancestor=$(docker image ls --filter reference=us-docker.pkg.dev/gradebot-451722/repository-1/gradebot:latest --format '\''{{.ID}}'\'') ; docker ps --latest --quiet --filter label=service=gradebot --filter label=destination= --filter label=role=job --filter status=running --filter status=restarting' | head -1 | xargs docker logs --timestamps 2>&1 | grep 'Starting Solid Queue with Rails env: production' on 34.44.244.114
  INFO [fc3517cb] Finished in 0.579 seconds with exit status 0 (successful).
App Host: 34.44.244.114
2025-03-15T00:45:03.117619971Z Starting Solid Queue with Rails env: production
```

- "Database config: ..." 
```
❯ bin/kamal app logs -r job -g "Database config"

  INFO [3f1d9615] Running /usr/bin/env sh -c 'docker ps --latest --quiet --filter label=service=gradebot --filter label=destination= --filter label=role=job --filter status=running --filter status=restarting --filter ancestor=$(docker image ls --filter reference=us-docker.pkg.dev/gradebot-451722/repository-1/gradebot:latest --format '\''{{.ID}}'\'') ; docker ps --latest --quiet --filter label=service=gradebot --filter label=destination= --filter label=role=job --filter status=running --filter status=restarting' | head -1 | xargs docker logs --timestamps 2>&1 | grep 'Database config' on 34.44.244.114
  INFO [3f1d9615] Finished in 0.639 seconds with exit status 0 (successful).
App Host: 34.44.244.114
2025-03-15T00:45:03.117626507Z Database config: [#<ActiveRecord::DatabaseConfigurations::HashConfig env_name=production name=primary adapter_class=ActiveRecord::ConnectionAdapters::SQLite3Adapter>, #<ActiveRecord::DatabaseConfigurations::HashConfig env_name=production name=cache adapter_class=ActiveRecord::ConnectionAdapters::SQLite3Adapter>, #<ActiveRecord::DatabaseConfigurations::HashConfig env_name=production name=queue adapter_class=ActiveRecord::ConnectionAdapters::SQLite3Adapter>, #<ActiveRecord::DatabaseConfigurations::HashConfig env_name=production name=cable adapter_class=ActiveRecord::ConnectionAdapters::SQLite3Adapter>]
```

- "Job worker config: ..."
```
~/code/gradebot main
❯ bin/kamal app logs -r job -g "Job worker config"

  INFO [1964a64d] Running /usr/bin/env sh -c 'docker ps --latest --quiet --filter label=service=gradebot --filter label=destination= --filter label=role=job --filter status=running --filter status=restarting --filter ancestor=$(docker image ls --filter reference=us-docker.pkg.dev/gradebot-451722/repository-1/gradebot:latest --format '\''{{.ID}}'\'') ; docker ps --latest --quiet --filter label=service=gradebot --filter label=destination= --filter label=role=job --filter status=running --filter status=restarting' | head -1 | xargs docker logs --timestamps 2>&1 | grep 'Job worker config' on 34.44.244.114
  INFO [1964a64d] Finished in 0.592 seconds with exit status 0 (successful).
App Host: 34.44.244.114
2025-03-15T00:45:03.117641401Z Job worker config: nil
```


- "Job concurrency: 2"

```
❯ bin/kamal app logs -r job -g "Job concurrency: 2"

  INFO [6bcae702] Running /usr/bin/env sh -c 'docker ps --latest --quiet --filter label=service=gradebot --filter label=destination= --filter label=role=job --filter status=running --filter status=restarting --filter ancestor=$(docker image ls --filter reference=us-docker.pkg.dev/gradebot-451722/repository-1/gradebot:latest --format '\''{{.ID}}'\'') ; docker ps --latest --quiet --filter label=service=gradebot --filter label=destination= --filter label=role=job --filter status=running --filter status=restarting' | head -1 | xargs docker logs --timestamps 2>&1 | grep 'Job concurrency: 2' on 34.44.244.114
  INFO [6bcae702] Finished in 0.676 seconds with exit status 0 (successful).
App Host: 34.44.244.114
2025-03-15T00:45:03.117646639Z Job concurrency: 2
```

## Step 4: Check Solid Queue status

Connect to the production console and check the status of Solid Queue:

```bash
bin/kamal console
```

Once in the console, run:

```ruby
SolidQueueStatus.check
```

This will show:
- Active processes and their details
- Number of ready, scheduled, claimed, and failed executions
- Database configuration information
- Queue database connection status

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
require_relative "lib/solid_queue_status"
SolidQueueStatus.list_jobs
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
require_relative "lib/solid_queue_status"
SolidQueueStatus.check_locks
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

1. **Missing tables**: If the Solid Queue tables don't exist, initialize them:
   ```ruby
   require_relative "lib/solid_queue_status"
   SolidQueueStatus.initialize_tables
   ```

2. **Database locking**: Change SQLite journal mode to WAL for better concurrency:
   ```ruby
   require_relative "lib/solid_queue_status" 
   SolidQueueStatus.set_wal_mode
   ```

3. **Check migrations status**: Verify the database migrations are up to date:
   ```ruby
   require_relative "lib/solid_queue_status"
   SolidQueueStatus.check_migrations
   ```

4. **Permission issues**: Fix permissions on the database files:
   ```bash
   chmod 666 /rails/storage/production_queue.sqlite3
   ```

5. **Database corruption**: If the database is corrupted, you may need to recreate it:
   ```bash
   # Backup first
   cp /rails/storage/production_queue.sqlite3 /rails/storage/production_queue.sqlite3.bak
   
   # Then recreate schema using Rails migrations (preferred)
   bin/rails db:schema:load:queue RAILS_ENV=production
   
   # Or use our utility to create the essential tables if migrations aren't working
   require_relative "lib/solid_queue_status"
   SolidQueueStatus.initialize_tables
   ```

6. **Consider using PostgreSQL**: For production deployments, consider switching to PostgreSQL for better concurrency handling.

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