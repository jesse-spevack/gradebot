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

### Result:

✅ Done!

```
❯ bin/kamal console
Get current version of running container...
  INFO [ddf3e151] Running /usr/bin/env sh -c 'docker ps --latest --format '\''{{.Names}}'\'' --filter label=service=gradebot --filter label=destination= --filter label=role=web --filter status=running --filter status=restarting --filter ancestor=$(docker image ls --filter reference=us-docker.pkg.dev/gradebot-451722/repository-1/gradebot:latest --format '\''{{.ID}}'\'') ; docker ps --latest --format '\''{{.Names}}'\'' --filter label=service=gradebot --filter label=destination= --filter label=role=web --filter status=running --filter status=restarting' | head -1 | while read line; do echo ${line#gradebot-web-}; done on 34.44.244.114
  INFO [ddf3e151] Finished in 0.741 seconds with exit status 0 (successful).
Launching interactive command with version 597e4674457ecad5242ccb9554e2210c815ab798 via SSH from existing container on 34.44.244.114...
LLM::EventSystem - Subscriber LLM::CostTrackingSubscriber registered for llm.request.completed
LLM Event System initialized with cost tracking subscriber
Loading production environment (Rails 8.0.2)
gradebot(prod)> SolidQueueStatus.check
=== SOLID QUEUE STATUS ===
Environment: production

Primary Database Configuration:
  Adapter: sqlite3
  Database: storage/production.sqlite3

Queue Database Configuration:
  Path: storage/production_queue.sqlite3
  Exists: true
  Size: 217088 bytes
  Permissions: 100644

Checking queue database connection directly:
  Checking database with sqlite3 command:
  Successfully opened database file with sqlite3 command
  Tables found: ar_internal_metadata, solid_queue_processes, schema_migrations, solid_queue_ready_executions, solid_queue_blocked_executions, solid_queue_recurring_executions, solid_queue_claimed_executions, solid_queue_recurring_tasks, solid_queue_failed_executions, solid_queue_scheduled_executions, solid_queue_jobs, solid_queue_semaphores, solid_queue_pauses,

Checking queue database connection with ActiveRecord:
  Connected successfully directly to the file
  Tables (13): solid_queue_failed_executions, solid_queue_jobs, solid_queue_pauses, solid_queue_scheduled_executions, solid_queue_processes, schema_migrations, solid_queue_recurring_executions, solid_queue_ready_executions, solid_queue_semaphores, solid_queue_recurring_tasks, solid_queue_blocked_executions, ar_internal_metadata, solid_queue_claimed_executions

Trying connected_to method:
  Error using connected_to: unknown keyword: :database

=== END STATUS ===
=> nil
gradebot(prod)>

```

## Step 5: Check database files

Still in the console, verify the database files:

```ruby
queue_db = ActiveRecord::Base.configurations.configs_for(env_name: Rails.env, name: 'queue')
File.exist?(queue_db.database)
File.stat(queue_db.database).mode.to_s(8)  # Check permissions
```

### Result:

✅ Done!

```
gradebot(prod)> queue_db = ActiveRecord::Base.configurations.configs_for(env_name: Rails.env, name: 'queue')
=> #<ActiveRecord::DatabaseConfigurations::HashConfig env_name=production name=queue adapter_class=ActiveRecord::ConnectionAdapters::SQLite3Adapter>
gradebot(prod)> File.exist?(queue_db.database)
=> true
gradebot(prod)> File.stat(queue_db.database).mode.to_s(8)  # Check permissions
=> "100644"
gradebot(prod)>
```

## Step 6: Enqueue a test job

Test job processing by enqueuing a test job:

```ruby
TestJob.perform_later("test_#{Time.current.to_i}")
```

### Result:

✅ Done!

```
gradebot(prod)> TestJob.perform_later("test_#{Time.current.to_i}")
[ActiveJob]   TRANSACTION (0.2ms)  BEGIN immediate TRANSACTION
[ActiveJob]   SolidQueue::Job Create (2.7ms)  INSERT INTO "solid_queue_jobs" ("queue_name", "class_name", "arguments", "priority", "active_job_id", "scheduled_at", "finished_at", "concurrency_key", "created_at", "updated_at") VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?) RETURNING "id"  [["queue_name", "default"], ["class_name", "TestJob"], ["arguments", "{\"job_class\":\"TestJob\",\"job_id\":\"df0abecf-9089-4c58-9cff-b23ff49cefea\",\"provider_job_id\":null,\"queue_name\":\"default\",\"priority\":null,\"arguments\":[\"test_1742002954\"],\"executions\":0,\"exception_executions\":{},\"locale\":\"en\",\"timezone\":\"UTC\",\"enqueued_at\":\"2025-03-15T01:42:34.281570408Z\",\"scheduled_at\":\"2025-03-15T01:42:34.281409608Z\"}"], ["priority", 0], ["active_job_id", "df0abecf-9089-4c58-9cff-b23ff49cefea"], ["scheduled_at", "2025-03-15 01:42:34.281409"], ["finished_at", nil], ["concurrency_key", "[FILTERED]"], ["created_at", "2025-03-15 01:42:34.301808"], ["updated_at", "2025-03-15 01:42:34.301808"]]
[ActiveJob]   TRANSACTION (0.1ms)  SAVEPOINT active_record_1
[ActiveJob]   SolidQueue::Job Load (0.3ms)  SELECT "solid_queue_jobs".* FROM "solid_queue_jobs" WHERE "solid_queue_jobs"."id" = ? LIMIT ?  [["id", 52], ["LIMIT", 1]]
[ActiveJob]   SolidQueue::ReadyExecution Create (0.3ms)  INSERT INTO "solid_queue_ready_executions" ("job_id", "queue_name", "priority", "created_at") VALUES (?, ?, ?, ?) RETURNING "id"  [["job_id", 52], ["queue_name", "default"], ["priority", 0], ["created_at", "2025-03-15 01:42:34.320756"]]
[ActiveJob]   TRANSACTION (0.1ms)  RELEASE SAVEPOINT active_record_1
[ActiveJob]   TRANSACTION (7.7ms)  COMMIT TRANSACTION
[ActiveJob] Enqueued TestJob (Job ID: df0abecf-9089-4c58-9cff-b23ff49cefea) to SolidQueue(default) with arguments: "test_1742002954"
=>
#<TestJob:0x00007fdbfef72998
 @_halted_callback_hook_called=nil,
 @arguments=["test_1742002954"],
 @exception_executions={},
 @executions=0,
 @job_id="df0abecf-9089-4c58-9cff-b23ff49cefea",
 @priority=nil,
 @provider_job_id=52,
 @queue_name="default",
 @scheduled_at=2025-03-15 01:42:34.281409608 UTC +00:00,
 @successfully_enqueued=true,
 @timezone="UTC">
gradebot(prod)>
```

## Step 7: Check job status

Check if the job was scheduled in the queue:

```ruby
require_relative "lib/solid_queue_status"
SolidQueueStatus.list_jobs
```

### Result:

✅ Done!

```
gradebot(prod)> SolidQueueStatus.list_jobs
=== PENDING JOBS ===
   (0.1ms)  SELECT COUNT(*) as count FROM solid_queue_ready_executions
Ready jobs: 3

Ready job details:
   (0.3ms)  SELECT r.id, r.job_id, j.class_name, j.arguments, r.created_at
FROM solid_queue_ready_executions r
JOIN solid_queue_jobs j ON r.job_id = j.id

  ID: 50, Job ID: 50
  Class: TestJob
  Arguments: {"job_class":"TestJob","job_id":"dda4f2aa-91ad-45fa-b9fc-cae76d7f2c61","provider_job_id":null,"queue_name":"default","priority":null,"arguments":["fresh_job_1741927183"],"executions":0,"exception_executions":{},"locale":"en","timezone":"UTC","enqueued_at":"2025-03-14T04:39:43.762092927Z","scheduled_at":"2025-03-14T04:39:43.762012817Z"}
  Created at: 2025-03-14 04:39:43.767612
  ---
  ID: 51, Job ID: 51
  Class: TestJob
  Arguments: {"job_class":"TestJob","job_id":"c8fa0256-9bc9-4d83-a056-66dce33e43fe","provider_job_id":null,"queue_name":"default","priority":null,"arguments":[],"executions":0,"exception_executions":{},"locale":"en","timezone":"UTC","enqueued_at":"2025-03-15T00:30:41.159803446Z","scheduled_at":"2025-03-15T00:30:41.159668976Z"}
  Created at: 2025-03-15 00:30:41.196825
  ---
  ID: 52, Job ID: 52
  Class: TestJob
  Arguments: {"job_class":"TestJob","job_id":"df0abecf-9089-4c58-9cff-b23ff49cefea","provider_job_id":null,"queue_name":"default","priority":null,"arguments":["test_1742002954"],"executions":0,"exception_executions":{},"locale":"en","timezone":"UTC","enqueued_at":"2025-03-15T01:42:34.281570408Z","scheduled_at":"2025-03-15T01:42:34.281409608Z"}
  Created at: 2025-03-15 01:42:34.320756
  ---
=> #<ActiveRecord::ConnectionAdapters::ConnectionPool env_name="production" role=:writing>
```
## Step 8: Monitor job logs

Exit the console and watch the job container logs to see if the test job gets processed:

```bash
bin/kamal logs -f -r job
```

Look for "=== TEST JOB EXECUTED AT ..." which indicates the job was processed.

### Result:

✅ Done!


```
❯ bin/kamal logs -f -r job
  INFO Following logs on 34.44.244.114...
  INFO ssh -t jesse@34.44.244.114 -p 22 'sh -c '\''docker ps --latest --quiet --filter label=service=gradebot --filter label=destination= --filter label=role=job --filter status=running --filter status=restarting --filter ancestor=$(docker image ls --filter reference=us-docker.pkg.dev/gradebot-451722/repository-1/gradebot:latest --format '\''\'\'''\''{{.ID}}'\''\'\'''\'') ; docker ps --latest --quiet --filter label=service=gradebot --filter label=destination= --filter label=role=job --filter status=running --filter status=restarting'\'' | head -1 | xargs docker logs --timestamps --tail 10 --follow 2>&1'
2025-03-15T01:45:35.516126767Z   SolidQueue::Process Update (0.1ms)  UPDATE "solid_queue_processes" SET "last_heartbeat_at" = ? WHERE "solid_queue_processes"."id" = ?  [["last_heartbeat_at", "2025-03-15 01:45:35.515011"], ["id", 267]]
2025-03-15T01:45:35.517822057Z   TRANSACTION (1.2ms)  COMMIT TRANSACTION
2025-03-15T01:45:35.530184142Z   TRANSACTION (0.2ms)  BEGIN immediate TRANSACTION
2025-03-15T01:45:35.530636162Z   SolidQueue::Process Load (0.7ms)  SELECT "solid_queue_processes".* FROM "solid_queue_processes" WHERE "solid_queue_processes"."id" = ? LIMIT ?   [["id", 268], ["LIMIT", 1]]
2025-03-15T01:45:35.532148237Z   SolidQueue::Process Update (0.1ms)  UPDATE "solid_queue_processes" SET "last_heartbeat_at" = ? WHERE "solid_queue_processes"."id" = ?  [["last_heartbeat_at", "2025-03-15 01:45:35.530924"], ["id", 268]]
2025-03-15T01:45:35.534218731Z   TRANSACTION (1.5ms)  COMMIT TRANSACTION
2025-03-15T01:45:35.547636105Z   TRANSACTION (0.2ms)  BEGIN immediate TRANSACTION
2025-03-15T01:45:35.548083353Z   SolidQueue::Process Load (0.7ms)  SELECT "solid_queue_processes".* FROM "solid_queue_processes" WHERE "solid_queue_processes"."id" = ? LIMIT ?   [["id", 269], ["LIMIT", 1]]
2025-03-15T01:45:35.549232713Z   SolidQueue::Process Update (0.1ms)  UPDATE "solid_queue_processes" SET "last_heartbeat_at" = ? WHERE "solid_queue_processes"."id" = ?  [["last_heartbeat_at", "2025-03-15 01:45:35.548338"], ["id", 269]]
2025-03-15T01:45:35.550802088Z   TRANSACTION (1.2ms)  COMMIT TRANSACTION
```

```
❯ bin/kamal app logs -r job -g "=== TEST JOB EXECUTED AT"
  INFO [cca3f316] Running /usr/bin/env sh -c 'docker ps --latest --quiet --filter label=service=gradebot --filter label=destination= --filter label=role=job --filter status=running --filter status=restarting --filter ancestor=$(docker image ls --filter reference=us-docker.pkg.dev/gradebot-451722/repository-1/gradebot:latest --format '\''{{.ID}}'\'') ; docker ps --latest --quiet --filter label=service=gradebot --filter label=destination= --filter label=role=job --filter status=running --filter status=restarting' | head -1 | xargs docker logs --timestamps 2>&1 | grep '=== TEST JOB EXECUTED AT' on 34.44.244.114
App Host: 34.44.244.114
Nothing found
```

## Step 9: Check for database locking issues

If jobs aren't processing, check for SQLite database locking issues:

```bash
bin/kamal console
```

```ruby
require_relative "lib/solid_queue_status"
SolidQueueStatus.check_locks
```

### Result:

✅ Done!

```
gradebot(prod)> SolidQueueStatus.check_locks
=== DATABASE LOCK STATUS ===
Checking with sqlite3 command line:
Command line result:
wal
0
   (1.2ms)  PRAGMA busy_timeout = 10000
Set busy timeout to 10000ms
   (0.1ms)  PRAGMA journal_mode
Journal mode: wal
   (0.1ms)  PRAGMA lock_status
Lock status: []
   (0.8ms)  PRAGMA integrity_check
Integrity check: ok
   (0.1ms)  BEGIN IMMEDIATE TRANSACTION
   (0.1ms)  ROLLBACK
Database is writable: Yes
=> #<ActiveRecord::ConnectionAdapters::ConnectionPool env_name="production" role=:writing>
```


## Step 10: Check for file permission issues

If suspecting file permission issues:

```bash
bin/kamal shell
```

```bash
ls -la /rails/storage/
```

### Result:

✅ Done!

```
❯ kamal shell
Get current version of running container...
  INFO [b32c1a62] Running /usr/bin/env sh -c 'docker ps --latest --format '\''{{.Names}}'\'' --filter label=service=gradebot --filter label=destination= --filter label=role=web --filter status=running --filter status=restarting --filter ancestor=$(docker image ls --filter reference=us-docker.pkg.dev/gradebot-451722/repository-1/gradebot:latest --format '\''{{.ID}}'\'') ; docker ps --latest --format '\''{{.Names}}'\'' --filter label=service=gradebot --filter label=destination= --filter label=role=web --filter status=running --filter status=restarting' | head -1 | while read line; do echo ${line#gradebot-web-}; done on 34.44.244.114
  INFO [b32c1a62] Finished in 0.604 seconds with exit status 0 (successful).
Launching interactive command with version 597e4674457ecad5242ccb9554e2210c815ab798 via SSH from existing container on 34.44.244.114...
rails@34:/rails$ ls -la /rails/storage/
total 7696
drwxr-xr-x 2 rails rails    4096 Mar 15 01:46 .
drwxr-xr-x 1 root  root     4096 Mar 15 01:33 ..
-rw-r--r-- 1 rails rails       0 Feb 23 04:59 .keep
-rw-r--r-- 1 rails rails  180224 Mar 13 14:48 production.sqlite3
-rw-r--r-- 1 rails rails 3244032 Mar 13 02:58 production_cable.sqlite3
-rw-r--r-- 1 rails rails   49152 Mar 13 14:47 production_cache.sqlite3
-rw-r--r-- 1 rails rails  217088 Mar 15 01:16 production_queue.sqlite3
-rw-r--r-- 1 rails rails   32768 Mar 15 01:47 production_queue.sqlite3-shm
-rw-r--r-- 1 rails rails 4140632 Mar 15 01:47 production_queue.sqlite3-wal
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


### Result:

✅ Done!


```
rails@34:/rails$ sqlite3 /rails/storage/production_queue.sqlite3 "PRAGMA integrity_check"
ok
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