# frozen_string_literal: true

require "test_helper"

class SequentialProcessingTest < ActionDispatch::IntegrationTest
  setup do
    # Create a grading task
    @user = users(:teacher)
    @grading_task = grading_tasks(:one)
    @grading_task.update!(user: @user)

    # Clear any existing submissions
    StudentSubmission.where(grading_task: @grading_task).delete_all

    # Create test submissions
    @submissions = []
    3.times do |i|
      @submissions << StudentSubmission.create!(
        grading_task: @grading_task,
        original_doc_id: "doc_#{i}",
        status: :pending
      )
    end
  end

  test "submissions are processed sequentially" do
    # Mock the ProcessStudentSubmissionCommand to track execution order
    execution_order = []

    # Create a mock command that records the submission ID when called
    ProcessStudentSubmissionCommand.stubs(:new).with do |args|
      submission_id = args[:student_submission_id]
      execution_order << submission_id

      # Return a mock command object
      mock = mock("Command")
      mock.stubs(:call).returns(mock)
      mock.stubs(:failure?).returns(false)
      mock
    end

    # Mock RetryHandler to avoid complexity
    RetryHandler.stubs(:with_retry).yields

    # Enqueue jobs for processing
    @submissions.each do |submission|
      StudentSubmissionJob.perform_later(submission.id)
    end

    # Process all jobs
    perform_enqueued_jobs

    # Verify that all submissions were processed
    assert_equal 3, execution_order.size

    # Verify that the submissions were processed in the order they were enqueued
    # This is important for sequential processing
    assert_equal @submissions.map(&:id), execution_order
  end

  test "handles API overload errors with retry" do
    # Create a submission for testing
    submission = @submissions.first

    # Mock the API client to raise an overload error on first call
    api_error = ApiOverloadError.new("Rate limit exceeded", retry_after: 0.1)

    # Track the number of attempts
    attempts = 0

    # Create a mock command that raises an error on first attempt
    ProcessStudentSubmissionCommand.stubs(:new).with do |args|
      attempts += 1

      if attempts == 1
        raise api_error
      end

      # Return a mock command object for subsequent attempts
      mock = mock("Command")
      mock.stubs(:call).returns(mock)
      mock.stubs(:failure?).returns(false)
      mock
    end

    # Process the job
    StudentSubmissionJob.perform_now(submission.id)

    # Verify that the job was retried
    assert_equal 2, attempts
  end
end
