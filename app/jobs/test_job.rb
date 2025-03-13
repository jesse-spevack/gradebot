# frozen_string_literal: true

# Simple job for testing background job processing
class TestJob < ApplicationJob
  queue_as :default

  def perform(*args)
    # Log that the job was processed
    Rails.logger.info "TestJob was processed at #{Time.current}"
    Rails.logger.info "Job arguments: #{args.inspect}" if args.present?
  end
end
