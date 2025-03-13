# frozen_string_literal: true

# Simple job for testing background job processing
class TestJob < ApplicationJob
  queue_as :default

  def perform(*args)
    # Log that the job was processed
    Rails.logger.info "TestJob was processed at #{Time.current}"

    # Create a file in the tmp directory to verify the job ran
    timestamp = Time.current.to_i
    File.write(Rails.root.join("tmp", "test_job_#{timestamp}.txt"), "Job processed at #{Time.current}")
  end
end
