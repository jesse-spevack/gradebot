# frozen_string_literal: true

require "test_helper"

class TestJobTest < ActiveJob::TestCase
  test "job creates a file in tmp directory" do
    # Setup
    tmp_dir = Rails.root.join("tmp")
    file_pattern = "test_job_*.txt"

    # Count existing files matching the pattern
    existing_files = Dir.glob(File.join(tmp_dir, file_pattern))

    # Perform the job
    TestJob.perform_now

    # Verify a new file was created
    new_files = Dir.glob(File.join(tmp_dir, file_pattern))
    assert_equal existing_files.size + 1, new_files.size,
      "Expected one new file to be created in tmp directory"

    # Get the newest file
    newest_file = new_files.max_by { |f| File.mtime(f) }

    # Verify file content
    content = File.read(newest_file)
    assert_match(/Job processed at/, content)
  end

  test "job is enqueued with correct queue" do
    assert_enqueued_with(job: TestJob, queue: "default") do
      TestJob.perform_later
    end
  end
end
