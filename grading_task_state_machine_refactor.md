# Grading Task State Machine Refactor

## Overview

This document outlines the plan for refactoring the grading task workflow to implement a sequential processing pipeline without using external state machine gems like AASM. The goal is to ensure that tasks are processed in a predictable order:

1. Process assignment prompt
2. Process grading rubric
3. Process student submissions

## Current Issues

Currently, the workflow has these problems:
- Jobs are enqueued simultaneously rather than sequentially
- Processing can happen in any order, which is confusing for users
- There are TODOs in the code indicating the need for sequential processing

## Implementation Plan

### 1. Expand GradingTask Status Enum

Enhance the existing status enum with more granular states to track the workflow:

```ruby
# app/models/grading_task.rb
enum status: {
  created: 0,                    # Initial state
  assignment_processing: 10,     # Assignment prompt is being processed
  assignment_processed: 20,      # Assignment prompt processing completed
  rubric_processing: 30,         # Rubric is being processed
  rubric_processed: 40,          # Rubric processing completed
  submissions_processing: 50,    # Student submissions are being processed
  completed: 60,                 # All processing is finished
  failed: 70                     # An error occurred during processing
}
```

### 2. Add Status Transition Methods

Add methods to handle state transitions with validation:

```ruby
# app/models/grading_task.rb

# Validation to ensure status transitions follow the correct sequence
validate :validate_status_transition, if: :status_changed?

# Helper methods for status transitions
def start_assignment_processing!
  return false unless may_start_assignment_processing?
  
  update!(status: :assignment_processing)
  # Enqueue the job
  FormatAssignmentPromptJob.perform_later(id)
  true
end

def complete_assignment_processing!
  return false unless may_complete_assignment_processing?
  
  update!(status: :assignment_processed)
  # Start the next step
  start_rubric_processing!
  true
end

# Additional transition methods for each state...

# Permission methods to check if transitions are allowed
def may_start_assignment_processing?
  created?
end

def may_complete_assignment_processing?
  assignment_processing?
end

# Additional permission methods...

private

# Validate that status transitions follow the correct sequence
def validate_status_transition
  return true if status_was.nil? # New record
  
  old_status = self.class.statuses[status_was]
  new_status = self.class.statuses[status]
  
  # Allow transition to failed from any state
  return true if status.to_sym == :failed
  
  # Ensure the new status is higher than the old status (forward progression)
  unless new_status > old_status
    errors.add(:status, "cannot transition from #{status_was} to #{status}")
  end
end
```

### 3. Update ProcessGradingTaskCommand

Modify the command to create submissions without enqueuing jobs and start the workflow:

```ruby
# app/commands/process_grading_task_command.rb
def execute
  grading_task = find_grading_task
  return nil unless grading_task

  begin
    # Fetch documents from Google Drive
    documents = fetch_documents(grading_task)
    return nil unless documents

    # Create student submissions without enqueuing jobs
    create_submissions_without_jobs(documents, grading_task)
    
    # Start the workflow
    grading_task.start_assignment_processing!

    # Return the grading task as the result
    grading_task
  rescue StandardError => e
    handle_error(e.message)
    grading_task.fail! if grading_task
    nil
  end
end

# New method to create submissions without enqueuing jobs
def create_submissions_without_jobs(documents, grading_task)
  submission_creator = SubmissionCreatorService.new(grading_task, documents, enqueue_jobs: false)
  submission_count = submission_creator.create_submissions

  if submission_count == 0
    handle_error("No submissions created from documents")
  else
    Rails.logger.info("Created #{submission_count} submissions for grading task #{grading_task_id}")
  end

  submission_count
end
```

### 4. Update SubmissionCreatorService

Modify the service to conditionally enqueue jobs:

```ruby
# app/services/submission_creator_service.rb
class SubmissionCreatorService
  # @param grading_task [GradingTask] The grading task to associate with submissions
  # @param documents [Array<Hash>] Array of document information hashes
  # @param enqueue_jobs [Boolean] Whether to enqueue processing jobs for each submission
  def initialize(grading_task, documents, enqueue_jobs: true)
    @grading_task = grading_task
    @documents = documents
    @enqueue_jobs = enqueue_jobs
  end
  
  # Enqueues a job to process the student submission
  # @param submission [StudentSubmission] The submission to process
  def enqueue_processing_job(submission)
    return unless @enqueue_jobs
    
    Rails.logger.info("Enqueuing processing job for submission #{submission.id}")
    StudentSubmissionJob.perform_later(submission.id)
  end
end
```

### 5. Update FormatAssignmentPromptJob

Modify the job to transition to the next state upon completion:

```ruby
# app/jobs/format_assignment_prompt_job.rb
def perform(grading_task_id)
  grading_task = GradingTask.find_by(id: grading_task_id)
  return unless grading_task
  
  # Ensure we're in the correct state
  return unless grading_task.assignment_processing?
  
  begin
    formatter = AssignmentPromptFormatterService.new
    formatter.format(grading_task)
    
    # Reload the grading task to ensure we have the latest data
    grading_task.reload
    
    # Broadcast the update to the UI
    Turbo::StreamsChannel.broadcast_replace_to(
      "grading_task_#{grading_task.id}",
      target: "assignment_prompt_container_#{grading_task.id}",
      partial: "grading_tasks/assignment_prompt_container",
      locals: { grading_task: grading_task }
    )
    
    # Transition to the next state
    grading_task.complete_assignment_processing!
  rescue => e
    Rails.logger.error("FormatAssignmentPromptJob failed with error: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    grading_task.fail!
  end
end
```

### 6. Update FormatGradingRubricJob

Modify the job to transition to the next state upon completion:

```ruby
# app/jobs/format_grading_rubric_job.rb
def perform(grading_task_id)
  grading_task = GradingTask.find_by(id: grading_task_id)
  return unless grading_task
  
  # Ensure we're in the correct state
  return unless grading_task.rubric_processing?
  
  begin
    formatter = GradingRubricFormatterService.new
    formatter.format(grading_task)
    
    # Reload the grading task to ensure we have the latest data
    grading_task.reload
    
    # Broadcast the update to the UI
    broadcast_update(grading_task)
    
    # Transition to the next state
    grading_task.complete_rubric_processing!
  rescue => e
    Rails.logger.error("FormatGradingRubricJob failed with error: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    grading_task.fail!
  end
end
```

### 7. Create StudentSubmissionsForGradingTaskJob

Create a new job to process all student submissions for a grading task:

```ruby
# app/jobs/student_submissions_for_grading_task_job.rb
class StudentSubmissionsForGradingTaskJob < ApplicationJob
  queue_as :student_submissions
  
  def perform(grading_task_id)
    grading_task = GradingTask.find_by(id: grading_task_id)
    return unless grading_task
    
    # Ensure we're in the correct state
    return unless grading_task.submissions_processing?
    
    begin
      # Get all student submissions for this grading task
      submissions = StudentSubmission.where(grading_task_id: grading_task_id)
      
      if submissions.empty?
        Rails.logger.warn("No student submissions found for grading task ID: #{grading_task_id}")
        grading_task.complete_processing!
        return
      end
      
      Rails.logger.info("Processing #{submissions.count} student submissions for grading task ID: #{grading_task_id}")
      
      # Process each submission
      process_all_submissions(submissions)
      
      # Mark the grading task as completed
      grading_task.complete_processing!
    rescue => e
      Rails.logger.error("StudentSubmissionsForGradingTaskJob failed: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      grading_task.fail!
    end
  end
  
  private
  
  def process_all_submissions(submissions)
    submissions.each do |submission|
      begin
        command = ProcessStudentSubmissionCommand.new(student_submission_id: submission.id).call
        
        if command.failure?
          Rails.logger.error("Failed to process student submission #{submission.id}: #{command.errors.join(', ')}")
        end
      rescue => e
        Rails.logger.error("Error processing student submission #{submission.id}: #{e.message}")
        
        # Update the submission status to failed
        StatusManager.transition_submission(
          submission,
          :failed,
          feedback: "Failed to complete grading: #{e.message}"
        )
      end
    end
  end
end
```

### 8. Add UI Helper Methods

Add methods to help with UI display:

```ruby
# app/models/grading_task.rb (additional methods)

# User-friendly status label
def status_label
  case status.to_sym
  when :created then "Created"
  when :assignment_processing then "Processing Assignment..."
  when :assignment_processed then "Assignment Processed"
  when :rubric_processing then "Processing Rubric..."
  when :rubric_processed then "Rubric Processed"
  when :submissions_processing then "Processing Submissions..."
  when :completed then "Completed"
  when :failed then "Failed"
  end
end

# Progress percentage based on status
def workflow_progress_percentage
  case status.to_sym
  when :created then 0
  when :assignment_processing then 15
  when :assignment_processed then 30
  when :rubric_processing then 45
  when :rubric_processed then 60
  when :submissions_processing then 80
  when :completed then 100
  when :failed then 100
  end
end
```

## Testing Strategy

### 1. Unit Tests for GradingTask

Test the state transition methods and validations:

```ruby
# test/models/grading_task_test.rb
test "follows correct workflow sequence" do
  grading_task = create(:grading_task)
  
  assert_equal "created", grading_task.status
  
  # Test transitions
  assert grading_task.may_start_assignment_processing?
  assert grading_task.start_assignment_processing!
  assert_equal "assignment_processing", grading_task.status
  
  assert grading_task.may_complete_assignment_processing?
  assert grading_task.complete_assignment_processing!
  assert_equal "assignment_processed", grading_task.status
  
  # Continue testing other transitions...
end

test "prevents invalid transitions" do
  grading_task = create(:grading_task)
  
  # Try to skip a step
  assert_not grading_task.may_complete_assignment_processing?
  assert_not grading_task.complete_assignment_processing!
  assert_equal "created", grading_task.status
  
  # Try to go backwards
  grading_task.update_column(:status, "assignment_processed")
  assert_not grading_task.may_start_assignment_processing?
  assert_not grading_task.start_assignment_processing!
  assert_equal "assignment_processed", grading_task.status
end
```

### 2. Integration Tests for Jobs

Test that jobs properly transition states:

```ruby
# test/jobs/format_assignment_prompt_job_test.rb
test "transitions state after processing" do
  grading_task = create(:grading_task, status: :assignment_processing)
  
  # Mock the formatter
  formatter = mock
  formatter.stubs(:format).returns(grading_task)
  AssignmentPromptFormatterService.stubs(:new).returns(formatter)
  
  # Stub broadcasts
  Turbo::StreamsChannel.stubs(:broadcast_replace_to).returns(nil)
  
  # Perform the job
  FormatAssignmentPromptJob.perform_now(grading_task.id)
  
  # Reload the grading task
  grading_task.reload
  
  # Check that the state transitioned
  assert_equal "assignment_processed", grading_task.status
end
```

### 3. End-to-End Tests

Test the complete workflow:

```ruby
# test/system/grading_tasks_test.rb
test "processes grading task in correct sequence" do
  # Setup
  grading_task = create(:grading_task)
  
  # Mock services to avoid actual API calls
  # ...
  
  # Execute the command
  ProcessGradingTaskCommand.new(grading_task_id: grading_task.id).call
  
  # Verify initial state
  assert_equal "assignment_processing", grading_task.reload.status
  
  # Run the first job
  perform_enqueued_jobs(only: FormatAssignmentPromptJob)
  assert_equal "rubric_processing", grading_task.reload.status
  
  # Run the second job
  perform_enqueued_jobs(only: FormatGradingRubricJob)
  assert_equal "submissions_processing", grading_task.reload.status
  
  # Run the final job
  perform_enqueued_jobs(only: StudentSubmissionsForGradingTaskJob)
  assert_equal "completed", grading_task.reload.status
end
```

## Implementation Steps

1. Update the GradingTask model with expanded status enum and transition methods
2. Create the StudentSubmissionsForGradingTaskJob
3. Update SubmissionCreatorService to support conditional job enqueuing
4. Update ProcessGradingTaskCommand to create submissions without enqueuing jobs
5. Update FormatAssignmentPromptJob to transition to the next state
6. Update FormatGradingRubricJob to transition to the next state
7. Add UI helper methods for displaying workflow status
8. Write tests for all components
9. Update views to show the new workflow status

## Benefits

- Clear, predictable sequence of operations
- Matches user expectations for workflow
- Reduces race conditions
- Simplifies error handling
- Eliminates TODOs in the current code
- No additional gem dependencies

## Potential Challenges

- Slightly increases overall processing time
- Creates tighter coupling between components
- If one job fails, the entire chain stops

## Future Extensibility

To add new steps to the workflow in the future:

1. Add new status values to the enum
2. Create new transition methods
3. Update the affected job to enqueue the new job
4. Create the new job
5. Update tests

This approach provides a robust state machine implementation using Rails' built-in features without introducing external dependencies. 