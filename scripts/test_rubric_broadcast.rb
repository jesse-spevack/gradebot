#!/usr/bin/env ruby
# Test script for verifying Rubric UI broadcasting
# Usage: rails runner scripts/test_rubric_broadcast.rb [setup|change|teardown]
#        If no argument is provided, all phases will be executed in sequence.

require "rails_helper" if defined?(Rails::TestUnitReporter)
require 'fileutils'

# Setup logging to tmp file
LOG_FILE = Rails.root.join("tmp", "rubric_broadcast_test_#{Time.current.strftime('%Y%m%d%H%M%S')}.log")
FileUtils.mkdir_p(File.dirname(LOG_FILE))
@file_logger = Logger.new(LOG_FILE)

# Define what phase(s) to run based on command line arguments
ARGV.shift if ARGV.first == "scripts/test_rubric_broadcast.rb" # Remove script name if present
phase = ARGV.first
run_all = phase.nil?
run_setup = run_all || phase == "setup"
run_change = run_all || phase == "change"
run_teardown = run_all || phase == "teardown"

# Cache file for storing object IDs between phases
CACHE_FILE = Rails.root.join("tmp", "rubric_broadcast_test_cache.json")

puts "===================================================="
puts "📡 RUBRIC BROADCAST TESTING SCRIPT"
puts "===================================================="
puts "Starting test at: #{Time.current}"
puts "Log file: #{LOG_FILE}"
puts "Running phases: #{run_setup ? 'setup ' : ''}#{run_change ? 'change ' : ''}#{run_teardown ? 'teardown' : ''}"
puts ""

# Helper method for consistent logging
def log_step(message)
  box_width = 70
  line = "=" * box_width

  puts "\n#{line}"
  puts "STEP: #{message}"
  puts "#{line}"
  Rails.logger.info "[BROADCAST TEST] #{message}"
  @file_logger.info "[BROADCAST TEST] #{message}"
end

# Helper to display object attributes for debugging
def display_object(object, name = nil)
  return puts "Object is nil" unless object

  title = name || object.class.name
  text = "\n== #{title} Details =="

  # Start with important attributes like ID and prefix ID for GradingTask
  attribute_texts = []
  if object.is_a?(GradingTask) && object.respond_to?(:prefix_id)
    attribute_texts << "  id: #{object.id} (#{object.prefix_id})"
  else
    attribute_texts << "  id: #{object.id}"
  end

  # Then add all other attributes
  attributes = object.attributes.except("created_at", "updated_at", "id")
  attribute_texts += attributes.map do |key, value|
    "  #{key}: #{value.inspect}"
  end

  attribute_texts << "  created_at: #{object.created_at}"
  attribute_texts << "  updated_at: #{object.updated_at}"

  full_text = [ text, *attribute_texts, "" ].join("\n")
  puts full_text
  @file_logger.info full_text
end

# Helper to save object IDs to cache file
def save_object_ids(objects)
  cache = {
    grading_task_id: objects[:grading_task]&.id,
    rubric_id: objects[:rubric]&.id,
    assignment_prompt_id: objects[:assignment_prompt]&.id,
    raw_rubric_id: objects[:raw_rubric]&.id
  }

  File.write(CACHE_FILE, JSON.generate(cache))
  log_step "💾 Saved object IDs to cache file: #{CACHE_FILE}"
  cache.each do |key, value|
    msg = "  #{key}: #{value.inspect}"
    puts msg
    @file_logger.info msg
  end
end

# Helper to load object IDs from cache file
def load_object_ids
  return {} unless File.exist?(CACHE_FILE)

  log_step "📂 Loading object IDs from cache file: #{CACHE_FILE}"
  cache = JSON.parse(File.read(CACHE_FILE))
  cache.transform_keys(&:to_sym).each do |key, value|
    msg = "  #{key}: #{value.inspect}"
    puts msg
    @file_logger.info msg
  end
  cache.transform_keys(&:to_sym)
rescue => e
  log_step "❌ Error loading cache file: #{e.message}"
  {}
end

# Helper to load objects from IDs
def load_objects(ids)
  objects = {
    grading_task: nil,
    rubric: nil,
    assignment_prompt: nil,
    raw_rubric: nil
  }

  if ids[:grading_task_id]
    objects[:grading_task] = GradingTask.find_by(id: ids[:grading_task_id])
    msg = "  - GradingTask: #{objects[:grading_task] ? 'Found' : 'Not found'}"
    puts msg
    @file_logger.info msg
  end

  if ids[:rubric_id]
    objects[:rubric] = Rubric.find_by(id: ids[:rubric_id])
    msg = "  - Rubric: #{objects[:rubric] ? 'Found' : 'Not found'}"
    puts msg
    @file_logger.info msg
  end

  if ids[:assignment_prompt_id]
    objects[:assignment_prompt] = AssignmentPrompt.find_by(id: ids[:assignment_prompt_id])
    msg = "  - AssignmentPrompt: #{objects[:assignment_prompt] ? 'Found' : 'Not found'}"
    puts msg
    @file_logger.info msg
  end

  if ids[:raw_rubric_id]
    objects[:raw_rubric] = RawRubric.find_by(id: ids[:raw_rubric_id])
    msg = "  - RawRubric: #{objects[:raw_rubric] ? 'Found' : 'Not found'}"
    puts msg
    @file_logger.info msg
  end

  objects
end

# Cleanup function
def cleanup(objects)
  log_step "🧹 Cleaning up created objects"

  # Delete in correct order to respect dependencies
  [ :grading_task, :assignment_prompt, :raw_rubric, :rubric ].each do |key|
    obj = objects[key]
    if obj && obj.persisted?
      msg = "  - Deleting #{obj.class.name} (id: #{obj.id})"
      puts msg
      @file_logger.info msg

      begin
        obj.destroy!
        msg = "    ✅ Successfully deleted"
        puts msg
        @file_logger.info msg
      rescue => e
        msg = "    ❌ Failed to delete: #{e.message}"
        puts msg
        @file_logger.info msg
      end
    else
      msg = "  - No #{key} to delete or not persisted"
      puts msg
      @file_logger.info msg
    end
  end

  # Remove cache file
  FileUtils.rm_f(CACHE_FILE) if File.exist?(CACHE_FILE)
  msg = "  - Removed cache file: #{CACHE_FILE}"
  puts msg
  @file_logger.info msg
end

begin
  # Ensure we're in development mode to avoid affecting production data
  unless Rails.env.development?
    puts "❌ This script should only be run in development environment!"
    puts "Current environment: #{Rails.env}"
    exit 1
  end

  # Set up objects - either create new ones or load from cache
  created_objects = {}

  if run_setup
    log_step "👤 Finding test user"
    # Use User.first as requested
    user = User.first
    if user.nil?
      puts "❌ No users found in the database."
      exit 1
    end

    msg = "✅ Found user: #{user.email} (id: #{user.id})"
    puts msg
    @file_logger.info msg

    log_step "🚀 Creating new grading task, assignment prompt, and rubric"

    # Prepare parameters for GradingTaskKickOffRequest
    assignment_title = "Test Broadcast Assignment Prompt"

    msg = "\n🧪 Creating GradingTaskKickOffRequest and calling KickOffService..."
    puts msg
    @file_logger.info msg

    # Ensure the environment has the right status values
    log_step "🔍 Checking model definitions"

    if GradingTask.respond_to?(:statuses)
      msg = "Available GradingTask statuses: #{GradingTask.statuses.keys.join(', ')}"
      puts msg
      @file_logger.info msg

      # Check for issues with CreationService
      creation_service_path = Rails.root.join("app/services/grading_task/creation_service.rb")
      if File.exist?(creation_service_path)
        content = File.read(creation_service_path)
        if content.include?("status: :created")
          msg = "⚠️ Warning: GradingTask::CreationService is using status: :created but valid values are: #{GradingTask.statuses.keys.join(', ')}"
          puts msg
          @file_logger.warn msg

          msg = "❌ Cannot proceed: The GradingTask::CreationService needs to be fixed to use a valid status."
          puts msg
          @file_logger.error msg

          msg = "📝 Please update app/services/grading_task/creation_service.rb to use status: :pending instead of status: :created"
          puts msg
          @file_logger.info msg

          exit 1
        end
      end
    else
      msg = "⚠️ Cannot determine GradingTask valid statuses"
      puts msg
      @file_logger.warn msg
    end

    # Create the request object with all required attributes
    begin
      # Create the request object with all required attributes
      request = GradingTaskKickOffRequest.new(
        user: user,
        feedback_tone: "encouraging",
        ai_generate_rubric: true,  # Generate rubric with AI
        assignment_prompt_title: assignment_title,
        assignment_prompt_subject: "Test Subject",
        assignment_prompt_grade_level: "College",
        assignment_prompt_word_count: 500,
        assignment_prompt_content: "This is a test assignment prompt created by the broadcast test script.",
        assignment_prompt_due_date: 2.weeks.from_now
      )

      # Log the request details
      msg = "  Created request object with attributes:"
      puts msg
      @file_logger.info msg

      %i[
        user feedback_tone ai_generate_rubric
        assignment_prompt_title assignment_prompt_subject assignment_prompt_grade_level
        assignment_prompt_word_count assignment_prompt_content assignment_prompt_due_date
      ].each do |attr|
        value = request.send(attr)
        value_display = attr == :user ? "#{value.class.name} ##{value.id}" : value.inspect
        msg = "    #{attr}: #{value_display}"
        puts msg
        @file_logger.info msg
      end

      # Validate the request
      unless request.valid?
        msg = "❌ Invalid request: #{request.errors.full_messages.join(', ')}"
        puts msg
        @file_logger.error msg
        raise msg
      end

      msg = "  ✅ Request is valid"
      puts msg
      @file_logger.info msg

      # Call the service with the request object
      begin
        grading_task = GradingTask::KickOffService.call(request)

        msg = "✅ Successfully created GradingTask ##{grading_task.id} (Prefix ID: #{grading_task.prefix_id})"
        puts msg
        @file_logger.info msg

        # Store created objects for later cleanup
        created_objects[:grading_task] = grading_task

        rubric = grading_task.rubric
        created_objects[:rubric] = rubric

        assignment_prompt = grading_task.assignment_prompt
        created_objects[:assignment_prompt] = assignment_prompt

        # Get raw_rubric if exists
        raw_rubric = rubric&.raw_rubric
        created_objects[:raw_rubric] = raw_rubric if raw_rubric

        puts "\n📊 Created Objects:"
        display_object(grading_task, "GradingTask")
        display_object(rubric, "Rubric")
        display_object(raw_rubric, "RawRubric") if raw_rubric
        display_object(assignment_prompt, "AssignmentPrompt")

        # Display URL for manual testing
        host = "localhost:3000"
        grading_task_url = "http://#{host}/grading_tasks/#{grading_task.id}"
        msg = "\n🌐 View the grading task at: #{grading_task_url}"
        puts msg
        @file_logger.info msg

        # Save object IDs for later phases
        save_object_ids(created_objects)
      rescue => e
        msg = "❌ Error creating GradingTaskKickOffRequest: #{e.message}"
        puts msg
        @file_logger.error msg
        exit 1 unless run_teardown && !run_change
      end
    rescue => e
      msg = "❌ Error creating GradingTaskKickOffRequest: #{e.message}"
      puts msg
      @file_logger.error msg
      exit 1
    end
  else
    # Load existing objects if not running setup
    created_objects = load_objects(load_object_ids) if run_change || run_teardown
  end

  # Change phase - test status transitions
  if run_change
    # Make sure we have a rubric to work with
    if created_objects[:rubric].nil?
      msg = "❌ No rubric available for status transitions."
      puts msg
      @file_logger.error msg
      exit 1 unless run_teardown
    else
      rubric = created_objects[:rubric]

      log_step "🔄 Testing rubric status transitions"
      msg = "Initial rubric status: #{rubric.status}"
      puts msg
      @file_logger.info msg

      # Test sequence: pending -> processing -> complete/failed
      # If we're using StatusManagerService:
      if defined?(Rubric::StatusManagerService)
        msg = "\n🔹 Testing Rubric::StatusManagerService transitions..."
        puts msg
        @file_logger.info msg

        if Rubric::StatusManagerService.respond_to?(:transition_to_processing)
          # Test success path: pending -> processing -> complete
          puts "  Transitioning to processing..."
          result = Rubric::StatusManagerService.transition_to_processing(rubric)
          msg = "  Result: #{result.inspect}"
          puts msg
          @file_logger.info msg

          msg = "  New status: #{rubric.reload.status}"
          puts msg
          @file_logger.info msg

          puts "  Testing broadcast..."
          broadcast_result = Rubric::BroadcasterService.broadcast(rubric)
          msg = "  Broadcast result: #{broadcast_result.inspect}"
          puts msg
          @file_logger.info msg
          sleep 3 # Wait a moment

          puts "\n  Transitioning to complete..."
          result = Rubric::StatusManagerService.transition_to_complete(rubric)
          msg = "  Result: #{result.inspect}"
          puts msg
          @file_logger.info msg

          msg = "  New status: #{rubric.reload.status}"
          puts msg
          @file_logger.info msg

          puts "  Testing broadcast..."
          broadcast_result = Rubric::BroadcasterService.broadcast(rubric)
          msg = "  Broadcast result: #{broadcast_result.inspect}"
          puts msg
          @file_logger.info msg
          sleep 3 # Wait a moment

          # Test failure path: We need a separate rubric in processing state
          log_step "Testing failure path with a new rubric"

          # Create a new rubric for testing the failure path
          new_rubric = Rubric.create!(
            title: "Test Failure Path Rubric",
            user: rubric.user,
            status: :pending
          )

          puts "  Created new rubric for failure path testing"
          display_object(new_rubric, "New Rubric")

          puts "  Transitioning new rubric to processing..."
          result = Rubric::StatusManagerService.transition_to_processing(new_rubric)
          msg = "  Result: #{result.inspect}"
          puts msg
          @file_logger.info msg

          msg = "  New status: #{new_rubric.reload.status}"
          puts msg
          @file_logger.info msg

          puts "  Testing broadcast..."
          broadcast_result = Rubric::BroadcasterService.broadcast(new_rubric)
          msg = "  Broadcast result: #{broadcast_result.inspect}"
          puts msg
          @file_logger.info msg
          sleep 3 # Wait a moment

          puts "\n  Transitioning to failed..."
          result = Rubric::StatusManagerService.transition_to_failed(new_rubric)
          msg = "  Result: #{result.inspect}"
          puts msg
          @file_logger.info msg

          msg = "  New status: #{new_rubric.reload.status}"
          puts msg
          @file_logger.info msg

          puts "  Testing broadcast..."
          broadcast_result = Rubric::BroadcasterService.broadcast(new_rubric)
          msg = "  Broadcast result: #{broadcast_result.inspect}"
          puts msg
          @file_logger.info msg

          # Clean up the temporary rubric
          new_rubric.destroy
        else
          msg = "  StatusManagerService exists but does not have transition_to_processing method."
          puts msg
          @file_logger.info msg
        end
      else
        # Direct status updates if StatusManagerService is not available
        msg = "\n🔹 Using direct status updates (StatusManagerService not available)..."
        puts msg
        @file_logger.info msg

        statuses = [ "pending", "processing", "complete", "failed" ]

        statuses.each do |status|
          next if rubric.status == status

          puts "  Updating status to #{status}..."
          rubric.update!(status: status)
          msg = "  New status: #{rubric.reload.status}"
          puts msg
          @file_logger.info msg

          puts "  Testing broadcast..."
          broadcast_result = Rubric::BroadcasterService.broadcast(rubric)
          msg = "  Broadcast result: #{broadcast_result.inspect}"
          puts msg
          @file_logger.info msg
          sleep 3 # Wait a moment
        end
      end

      # Final state display
      puts "\n📊 Final Rubric State:"
      display_object(rubric.reload, "Rubric")

      msg = "\n✅ Status transition testing complete!"
      puts msg
      @file_logger.info msg
    end
  end

  # Teardown phase - cleanup objects
  if run_teardown
    cleanup(created_objects)
  else
    msg = "\nSkipping cleanup. Run with 'teardown' argument later to clean up objects."
    puts msg
    @file_logger.info msg
  end
ensure
  msg = "\n===================================================="
  puts msg
  @file_logger.info msg

  msg = "📡 TEST SCRIPT COMPLETED at: #{Time.current}"
  puts msg
  @file_logger.info msg

  msg = "📝 Log file: #{LOG_FILE}"
  puts msg
  @file_logger.info msg

  msg = "===================================================="
  puts msg
  @file_logger.info msg

  @file_logger.close
end
