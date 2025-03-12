# frozen_string_literal: true

module Admin
  # Controller for monitoring background job processing
  # Provides an interface to view queue statistics and job status
  class JobMonitoringController < Admin::BaseController
    def index
      @queue_stats = collect_queue_stats

      respond_to do |format|
        format.html
        format.json { render json: @queue_stats }
      end
    end

    private

    # Collect statistics for all queues
    # @return [Hash] Statistics for each queue
    def collect_queue_stats
      stats = {}

      # Get all defined queue names - use the known queue names from our configuration
      queue_names = [ :student_submissions, :formatting, :default, :mailers ]

      queue_names.each do |queue_name|
        # Count pending jobs for each queue
        pending_count = SolidQueue::Job.where(queue_name: queue_name, scheduled_at: nil)
                                      .where("finished_at IS NULL")
                                      .count

        # Count scheduled jobs
        scheduled_count = SolidQueue::Job.where(queue_name: queue_name)
                                        .where("scheduled_at IS NOT NULL")
                                        .where("finished_at IS NULL")
                                        .count

        # Count failed jobs
        failed_count = SolidQueue::Job.where(queue_name: queue_name)
                                     .joins("INNER JOIN solid_queue_failed_executions ON solid_queue_jobs.id = solid_queue_failed_executions.job_id")
                                     .count

        # Count completed jobs in the last hour
        completed_count = SolidQueue::Job.where(queue_name: queue_name)
                                        .where("finished_at IS NOT NULL")
                                        .where("finished_at > ?", 1.hour.ago)
                                        .count

        # Get concurrency setting for the queue based on queue.yml
        concurrency = queue_concurrency(queue_name)

        stats[queue_name] = {
          pending: pending_count,
          scheduled: scheduled_count,
          failed: failed_count,
          completed_last_hour: completed_count,
          total_unfinished: pending_count + scheduled_count,
          concurrency: concurrency
        }
      end

      stats
    end

    # Determine the concurrency for a queue based on our queue.yml configuration
    # @param queue_name [Symbol] The name of the queue
    # @return [Integer] The concurrency value
    def queue_concurrency(queue_name)
      case queue_name.to_sym
      when :student_submissions
        1  # Sequential processing
      when :formatting
        2  # Limited concurrency
      else
        5  # Default concurrency
      end
    end
  end
end
