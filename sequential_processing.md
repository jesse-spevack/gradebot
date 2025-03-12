# Sequential Processing Implementation Plan for Gradebot

## Current Problem

Our application is hitting Anthropic API rate limits (10,000 output tokens per minute) when processing multiple student submissions concurrently. This happens because:

1. When a grading task is processed, multiple student submission jobs are enqueued simultaneously
2. These jobs run in parallel, each making API calls to Anthropic
3. The combined token usage exceeds the rate limit
4. While we've properly defined `ApiOverloadError`, our retry mechanism isn't being triggered effectively

## Phase 1: Simple Sequential Processing

### Implementation Steps

1. **Create a dedicated queue for LLM operations**

   Update the `StudentSubmissionJob` to use a dedicated queue:

   ```ruby
   # app/jobs/student_submission_job.rb
   class StudentSubmissionJob < ApplicationJob
     queue_as :student_submissions # Change from :default to :student_submissions
     
     def perform(student_submission_id)
       # Existing implementation...
     end
   end
   ```

2. **Configure sequential processing** 
    ```ruby
    # config/initializers/solid_queue.rb

    Rails.application.configure do
    config.solid_queue.polling_interval = 1.second
    
    # Configure a specific queue for sequential processing
    # The key part here is setting concurrency: 1 for your sequential queue. 
    # This ensures that only one job from this queue runs at a time, guaranteeing sequential processing.
    config.solid_queue.queues.register(:student_submissions, concurrency: 1)
    end
    ```

3. **Enhance the RetryHandler integration**

   Update the `StudentSubmissionJob` to use the RetryHandler:

   ```ruby
   # app/jobs/student_submission_job.rb
   class StudentSubmissionJob < ApplicationJob
     queue_as :student_submissions
     
     def perform(student_submission_id)
       RetryHandler.with_retry(error_class: ApiOverloadError, max_retries: 5, base_delay: 2) do
         # Call the command to process the student submission
         command = ProcessStudentSubmissionCommand.new(student_submission_id: student_submission_id).call
         
         if command.failure?
           # Log any errors that occurred during processing
           Rails.logger.error("StudentSubmissionJob failed: #{command.errors.join(', ')}")
         end
       end
     rescue => e
       Rails.logger.error("StudentSubmissionJob failed with unhandled error: #{e.message}")
       Rails.logger.error(e.backtrace.join("\n"))
       
       # Update the submission status to failed
       submission = StudentSubmission.find_by(id: student_submission_id)
       if submission
         StatusManager.transition_submission(
           submission, 
           :failed, 
           feedback: "Failed to complete grading: #{e.message}"
         )
       end
     end
   end
   ```

4. **Ensure ApiOverloadError is properly required**

   Verify that `ApiOverloadError` is properly required in all relevant files:

   ```ruby
   # app/services/retry_handler.rb
   require_relative '../errors/api_overload_error'
   
   class RetryHandler
     # Existing implementation...
   end
   ```

5. **Add improved logging for rate limit tracking**

   Enhance logging in the Anthropic client:

   ```ruby
   # lib/llm/anthropic/client.rb
   # In the execute_request method, when handling rate limiting errors:
   
   if response.code.to_i == 429
     retry_after = response["retry-after"].to_i if response["retry-after"]
     retry_after ||= 60
     
     Rails.logger.warn("RATE LIMIT EXCEEDED: Anthropic API rate limit hit. Retry after: #{retry_after} seconds")
     Rails.logger.warn("Rate limit details: #{error_msg}")
     
     # Existing code to raise ApiOverloadError...
   end
   ```

6. **Add monitoring for job processing**

   Create a simple monitoring endpoint to track job processing:

   ```ruby
   # app/controllers/admin/job_monitoring_controller.rb
   module Admin
     class JobMonitoringController < ApplicationController
       before_action :require_admin
       
       def index
    @queue_stats = collect_queue_stats
    
    respond_to do |format|
      format.html
      format.json { render json: @queue_stats }
    end
  end
  
  private
  
  def collect_queue_stats
    stats = {}
    
    # Get all defined queue names
    queue_names = SolidQueue.queues.keys
    
    queue_names.each do |queue_name|
      # Count pending jobs for each queue
      pending_count = SolidQueue::Job.where(queue_name: queue_name, scheduled_at: nil)
                                    .where('failed_at IS NULL')
                                    .count
                                    
      # Count scheduled jobs
      scheduled_count = SolidQueue::Job.where(queue_name: queue_name)
                                      .where('scheduled_at IS NOT NULL')
                                      .where('failed_at IS NULL')
                                      .count
                                      
      # Count failed jobs
      failed_count = SolidQueue::Job.where(queue_name: queue_name)
                                   .where('failed_at IS NOT NULL')
                                   .count
      
      stats[queue_name] = {
        pending: pending_count,
        scheduled: scheduled_count,
        failed: failed_count,
        total: pending_count + scheduled_count
      }
    end
    
    stats
  end
     end
   end
   ```

## Phase 2: Future Expansion for Multiple Users

When we have multiple users, we'll need to enhance our approach to ensure fairness and efficiency. Here's how we'll expand:

### Implementation Plan for Multi-User Support

1. **Add user context to jobs**

   Enhance the job to include user context:

   ```ruby
   # app/services/submission_creator_service.rb
   def enqueue_processing_job(submission)
     Rails.logger.info("Enqueuing processing job for submission #{submission.id}")
     
     # Add user context as job metadata
     StudentSubmissionJob.set(
       queue: :llm_requests,
       user_context: {
         user_id: @grading_task.user_id,
         grading_task_id: @grading_task.id
       }
     ).perform_later(submission.id)
   end
   ```

2. **Create a Submission Coordinator**

   Implement a coordinator service to manage fair scheduling:

   ```ruby
   # app/services/submission_coordinator_service.rb
   class SubmissionCoordinatorService
     # Find the next submission to process using round-robin between users
     def self.next_submission_to_process
       # Get all users with pending submissions
       users_with_pending = GradingTask.joins(:student_submissions)
                                      .where(student_submissions: { status: :pending })
                                      .distinct
                                      .pluck(:user_id)
       
       return nil if users_with_pending.empty?
       
       # Find the user who hasn't been processed recently
       next_user = find_least_recently_processed_user(users_with_pending)
       
       # Get the oldest pending submission for this user
       StudentSubmission.joins(:grading_task)
                       .where(status: :pending, grading_tasks: { user_id: next_user })
                       .order(created_at: :asc)
                       .first
     end
     
     private
     
     def self.find_least_recently_processed_user(user_ids)
       # Track last processed time in Redis or similar
       # For simplicity, we'll use the oldest pending submission as a proxy
       user_processing_times = user_ids.map do |user_id|
         last_submission = StudentSubmission.joins(:grading_task)
                                          .where(grading_tasks: { user_id: user_id })
                                          .where.not(status: :pending)
                                          .order(updated_at: :desc)
                                          .first
         
         last_time = last_submission ? last_submission.updated_at : Time.at(0)
         [user_id, last_time]
       end
       
       # Return the user with the oldest last processing time
       user_processing_times.min_by { |_, time| time }.first
     end
   end
   ```

3. **Implement a Dispatcher Job**

   Create a job to manage the processing queue:

   ```ruby
   # app/jobs/submission_dispatcher_job.rb
   class SubmissionDispatcherJob < ApplicationJob
     queue_as :dispatcher
     
     def perform
       # Find the next submission to process based on fair scheduling
       next_submission = SubmissionCoordinatorService.next_submission_to_process
       
       if next_submission
         # Process it
         process_submission(next_submission)
       end
       
       # Re-enqueue self to continue processing
       self.class.set(wait: 5.seconds).perform_later unless Rails.env.test?
     end
     
     private
     
     def process_submission(submission)
       # Update status to show it's been picked up
       StatusManager.transition_submission(submission, :processing)
       
       # Process the submission
       StudentSubmissionProcessorJob.perform_later(submission.id)
     end
   end
   ```

4. **Create a Processor Job**

   Split the processing logic into a separate job:

   ```ruby
   # app/jobs/student_submission_processor_job.rb
   class StudentSubmissionProcessorJob < ApplicationJob
     queue_as :llm_processor
     
     def perform(submission_id)
       RetryHandler.with_retry(error_class: ApiOverloadError, max_retries: 5, base_delay: 2) do
         # Process a single submission
         command = ProcessStudentSubmissionCommand.new(student_submission_id: submission_id).call
         
         if command.failure?
           Rails.logger.error("StudentSubmissionProcessorJob failed: #{command.errors.join(', ')}")
         end
       end
     rescue => e
       Rails.logger.error("StudentSubmissionProcessorJob failed with unhandled error: #{e.message}")
       
       # Update the submission status to failed
       submission = StudentSubmission.find_by(id: submission_id)
       if submission
         StatusManager.transition_submission(
           submission, 
           :failed, 
           feedback: "Failed to complete grading: #{e.message}"
         )
       end
     end
   end
   ```

5. **Add Feature Flag for Gradual Rollout**

   Implement a feature flag to control the transition:

   ```ruby
   # app/services/submission_creator_service.rb
   def enqueue_processing_job(submission)
     Rails.logger.info("Enqueuing processing job for submission #{submission.id}")
     
     if FeatureFlag.enabled?(:user_aware_scheduling)
       # Let the dispatcher handle it
       # The submission will be picked up by the dispatcher job
     else
       # Use the direct approach
       StudentSubmissionJob.perform_later(submission.id)
     end
   end
   ```

6. **Initialize the Dispatcher on Application Start**

   Ensure the dispatcher is running:

   ```ruby
   # config/initializers/submission_dispatcher.rb
   Rails.application.config.after_initialize do
     if Rails.env.production? && FeatureFlag.enabled?(:user_aware_scheduling)
       # Start the dispatcher if it's not already running
       unless Sidekiq::Workers.new.any? { |_, _, work| work["class"] == "SubmissionDispatcherJob" }
         SubmissionDispatcherJob.perform_later
       end
     end
   end
   ```

## Testing Plan

1. **Unit Tests**

   ```ruby
   # test/jobs/student_submission_job_test.rb
   test "uses retry handler for API overload errors" do
     submission = create(:student_submission)
     
     # Mock the command to raise an ApiOverloadError on first call, then succeed
     mock_command = mock
     mock_command.stubs(:call).raises(ApiOverloadError.new("Rate limit exceeded")).then.returns(mock_command)
     mock_command.stubs(:failure?).returns(false)
     
     ProcessStudentSubmissionCommand.expects(:new).returns(mock_command)
     
     # The job should complete successfully despite the error
     assert_nothing_raised do
       StudentSubmissionJob.perform_now(submission.id)
     end
   end
   ```

2. **Integration Tests**

   ```ruby
   # test/integration/sequential_processing_test.rb
   test "submissions are processed sequentially" do
     # Create a grading task with multiple submissions
     grading_task = create(:grading_task)
     submissions = create_list(:student_submission, 3, grading_task: grading_task, status: :pending)
     
     # Enqueue jobs for processing
     submissions.each do |submission|
       StudentSubmissionJob.perform_later(submission.id)
     end
     
     # Verify only one job runs at a time
     assert_equal 1, Sidekiq::Workers.new.count { |_, _, work| work["queue"] == "llm_requests" }
     
     # Process all jobs
     perform_enqueued_jobs
     
     # Verify all submissions were processed
     submissions.each do |submission|
       submission.reload
       assert_not_equal "pending", submission.status
     end
   end
   ```

## Monitoring and Metrics

1. **Key Metrics to Track**

   - Rate limit errors per hour
   - Average job processing time
   - Queue depth over time
   - Jobs processed per minute
   - Success/failure rate

2. **Alerting**

   Set up alerts for:
   - Queue depth exceeding threshold (e.g., > 100 jobs)
   - High rate of rate limit errors (e.g., > 10 per hour)
   - Jobs taking too long to process (e.g., > 5 minutes)

## Rollout Plan

1. **Development Testing**
   - Implement and test in development environment
   - Verify with simulated load

2. **Staging Deployment**
   - Deploy to staging
   - Run load tests to verify behavior

3. **Production Rollout**
   - Deploy code changes
   - Monitor closely for first 24 hours
   - Be prepared to roll back if issues arise

4. **Evaluation**
   - After 1 week, evaluate performance
   - Decide whether to proceed with multi-user enhancements

## Conclusion

This implementation plan provides a clear path forward:

1. **Immediate Solution**: Sequential processing to solve the current rate limiting issues
2. **Future Expansion**: A framework for fair, user-aware job scheduling as our needs evolve
3. **Gradual Transition**: Feature flags and backward compatibility to ensure a smooth rollout

By following this plan, we'll address the immediate rate limiting problems while setting the foundation for a more sophisticated system as our needs evolve.
