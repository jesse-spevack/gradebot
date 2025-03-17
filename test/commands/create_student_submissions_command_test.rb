require "test_helper"

class CreateStudentSubmissionsCommandTest < ActiveSupport::TestCase
  setup do
    @user = users(:teacher)
    @grading_task = grading_tasks(:one)
  end

  test "successfully creates submissions" do
    # Setup
    mock_token_service = Minitest::Mock.new
    mock_token_service.expect :fetch_token, "fake_token"

    mock_document_fetcher = Minitest::Mock.new
    mock_document_fetcher.expect :fetch, [
      { id: "doc1", name: "Document 1" },
      { id: "doc2", name: "Document 2" }
    ]

    mock_submission_creator = Minitest::Mock.new
    mock_submission_creator.expect :create_submissions, 2

    # Exercise
    GradingTaskAccessTokenService.stub :new, mock_token_service do
      FolderDocumentFetcherService.stub :new, mock_document_fetcher do
        # Verify that SubmissionCreatorService is created without enqueue_jobs
        SubmissionCreatorService.stub :new, ->(grading_task, documents) {
          assert_equal @grading_task, grading_task
          mock_submission_creator
        } do
          command = CreateStudentSubmissionsCommand.new(grading_task: @grading_task)
          result = command.call

          # Verify
          assert_equal 2, result.result
          assert_empty result.errors
        end
      end
    end

    # Verify all mocks were called as expected
    assert_mock mock_token_service
    assert_mock mock_document_fetcher
    assert_mock mock_submission_creator
  end

  test "handles token service error" do
    # Setup
    mock_token_service = Minitest::Mock.new
    mock_token_service.expect :fetch_token, nil do
      raise StandardError, "Token error"
    end

    # Exercise
    GradingTaskAccessTokenService.stub :new, mock_token_service do
      command = CreateStudentSubmissionsCommand.new(grading_task: @grading_task)
      result = command.call

      # Verify
      assert_nil result.result
      assert_includes result.errors, "Token error"
    end
  end

  test "handles document fetcher error" do
    # Setup
    mock_token_service = Minitest::Mock.new
    mock_token_service.expect :fetch_token, "fake_token"

    mock_document_fetcher = Minitest::Mock.new
    mock_document_fetcher.expect :fetch, nil do
      raise StandardError, "Fetcher error"
    end

    # Exercise
    GradingTaskAccessTokenService.stub :new, mock_token_service do
      FolderDocumentFetcherService.stub :new, mock_document_fetcher do
        command = CreateStudentSubmissionsCommand.new(grading_task: @grading_task)
        result = command.call

        # Verify
        assert_nil result.result
        assert_includes result.errors, "Fetcher error"
      end
    end
  end

  test "handles submission creator error" do
    # Setup
    mock_token_service = Minitest::Mock.new
    mock_token_service.expect :fetch_token, "fake_token"

    mock_document_fetcher = Minitest::Mock.new
    mock_document_fetcher.expect :fetch, [
      { id: "doc1", name: "Document 1" },
      { id: "doc2", name: "Document 2" }
    ]

    mock_submission_creator = Minitest::Mock.new
    mock_submission_creator.expect :create_submissions, nil do
      raise StandardError, "Creator error"
    end

    # Exercise
    GradingTaskAccessTokenService.stub :new, mock_token_service do
      FolderDocumentFetcherService.stub :new, mock_document_fetcher do
        SubmissionCreatorService.stub :new, ->(grading_task, documents) {
          mock_submission_creator
        } do
          command = CreateStudentSubmissionsCommand.new(grading_task: @grading_task)
          result = command.call

          # Verify
          assert_nil result.result
          assert_includes result.errors, "Creator error"
        end
      end
    end
  end

  test "handles no submissions created" do
    # Setup
    mock_token_service = Minitest::Mock.new
    mock_token_service.expect :fetch_token, "fake_token"

    mock_document_fetcher = Minitest::Mock.new
    mock_document_fetcher.expect :fetch, [
      { id: "doc1", name: "Document 1" },
      { id: "doc2", name: "Document 2" }
    ]

    mock_submission_creator = Minitest::Mock.new
    mock_submission_creator.expect :create_submissions, 0

    # Exercise
    GradingTaskAccessTokenService.stub :new, mock_token_service do
      FolderDocumentFetcherService.stub :new, mock_document_fetcher do
        SubmissionCreatorService.stub :new, ->(grading_task, documents) {
          mock_submission_creator
        } do
          command = CreateStudentSubmissionsCommand.new(grading_task: @grading_task)
          result = command.call

          # Verify
          assert_equal 0, result.result
          assert_empty result.errors
        end
      end
    end
  end
end
