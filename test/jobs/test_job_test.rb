# frozen_string_literal: true

require "test_helper"

class TestJobTest < ActiveJob::TestCase
  test "job is enqueued with correct queue" do
    assert_enqueued_with(job: TestJob, queue: "default") do
      TestJob.perform_later
    end
  end
end
