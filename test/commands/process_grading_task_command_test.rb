require "test_helper"
require "minitest/mock"

class ProcessGradingTaskCommandTest < ActiveJob::TestCase
  # Setup
  setup do
    @user = users(:teacher)
    @grading_task = grading_tasks(:one)
    @folder_id = @grading_task.folder_id

    # Mock document data that would be returned from Google Drive
    @mock_documents = [
      { id: "doc1", name: "Student 1 - Assignment.docx" },
      { id: "doc2", name: "Student 2 - Assignment.docx" },
      { id: "doc3", name: "Student 3 - Assignment.docx" }
    ]

    # Clear existing submissions for the grading task
    StudentSubmission.where(grading_task: @grading_task).delete_all
  end

  test "fetches documents from Google Drive and creates submissions" do
    # Setup - Mock the Google Drive service
    drive_service_mock = Minitest::Mock.new

    # Expect drive_service to list files in the folder
    drive_service_mock.expect :list_files_in_folder, @mock_documents, [ String ]

    # Stub the access_token method to return a placeholder token
    ProcessGradingTaskCommand.any_instance.stubs(:access_token).returns("test_token")

    # Stub the GoogleDriveService to return our mock
    GoogleDriveService.stub :new, drive_service_mock do
      # Initial count of student submissions
      initial_count = StudentSubmission.count

      # Exercise - Run the command
      command = ProcessGradingTaskCommand.new(grading_task_id: @grading_task.id).call

      # Verify
      # 1. Command succeeded
      assert command.success?

      # 2. New submissions were created
      assert_equal initial_count + 3, StudentSubmission.count

      # 3. Submissions have correct attributes
      submissions = StudentSubmission.where(grading_task: @grading_task).order(:created_at)
      assert_equal 3, submissions.size

      submissions.each_with_index do |submission, i|
        doc = @mock_documents[i]
        assert_equal doc[:id], submission.original_doc_id
        assert_equal "pending", submission.status
        assert_equal @grading_task.id, submission.grading_task_id
      end
    end
  end

  test "enqueues StudentSubmissionJob for each submission" do
    # Setup - Mock the Google Drive service
    drive_service_mock = Minitest::Mock.new
    drive_service_mock.expect :list_files_in_folder, @mock_documents, [ String ]

    # Stub the access_token method to return a placeholder token
    ProcessGradingTaskCommand.any_instance.stubs(:access_token).returns("test_token")

    # Exercise & Verify
    GoogleDriveService.stub :new, drive_service_mock do
      # Verify that jobs are enqueued
      assert_enqueued_with(job: StudentSubmissionJob) do
        command = ProcessGradingTaskCommand.new(grading_task_id: @grading_task.id).call
      end

      # Get the created submissions to verify each submission has a job
      submissions = StudentSubmission.where(grading_task: @grading_task).order(:created_at)
      assert_equal 3, submissions.size
    end
  end

  test "handles empty folders" do
    # Setup - Mock the Google Drive service to return empty list
    drive_service_mock = Minitest::Mock.new
    drive_service_mock.expect :list_files_in_folder, [], [ String ]

    # Stub the access_token method to return a placeholder token
    ProcessGradingTaskCommand.any_instance.stubs(:access_token).returns("test_token")

    # Exercise & Verify
    GoogleDriveService.stub :new, drive_service_mock do
      # Initial count of student submissions for this grading task
      initial_count = StudentSubmission.where(grading_task: @grading_task).count

      # Run the command
      command = ProcessGradingTaskCommand.new(grading_task_id: @grading_task.id).call

      # Verify command succeeded but no submissions created for this task
      assert command.success?
      assert_equal initial_count, StudentSubmission.where(grading_task: @grading_task).count
    end
  end

  test "handles Google Drive service errors" do
    # Setup - Mock the Google Drive service to raise an error
    drive_service_mock = Minitest::Mock.new
    drive_service_mock.expect :list_files_in_folder, nil do
      raise GoogleDriveService::ApiError, "API Error"
    end

    # Stub the access_token method to return a placeholder token
    ProcessGradingTaskCommand.any_instance.stubs(:access_token).returns("test_token")

    # Delete existing submissions for this test
    StudentSubmission.where(grading_task: @grading_task).delete_all

    # Exercise & Verify
    GoogleDriveService.stub :new, drive_service_mock do
      # Run the command
      command = ProcessGradingTaskCommand.new(grading_task_id: @grading_task.id).call

      # Verify command failed with error message
      assert command.failure?
      assert_match /Failed to fetch documents/, command.errors.join(", ")

      # No submissions should be created when there's an error
      assert_empty StudentSubmission.where(grading_task: @grading_task)
    end
  end
end
