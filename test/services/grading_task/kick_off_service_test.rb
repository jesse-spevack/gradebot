require "test_helper"

class GradingTask::KickOffServiceTest < ActiveSupport::TestCase
  include ActionText::SystemTestHelper

  test "orchestrates creation of grading task, assignment prompt, and rubric" do
    # Setup
    user = users(:teacher)

    # Create a valid request
    request = GradingTaskKickOffRequest.new(
      user: user,
      rubric_raw_text: "Content: 40%, Structure: 30%, Grammar: 30%",
      assignment_prompt_title: "Test Assignment",
      assignment_prompt_subject: "English",
      assignment_prompt_grade_level: "10",
      assignment_prompt_word_count: "500",
      assignment_prompt_content: "Write an essay about climate change.",
      document_data: []
    )

    # Exercise
    grading_task = GradingTask::KickOffService.call(request)

    # Verify
    assert grading_task.persisted?
    assert_equal user, grading_task.user
    assert_equal "created", grading_task.status
    assert_nil grading_task.feedback_tone

    # Verify assignment prompt
    assignment_prompt = grading_task.assignment_prompt
    assert assignment_prompt.persisted?
    assert_equal "Test Assignment", assignment_prompt.title
    assert_equal "English", assignment_prompt.subject

    # Verify rubric
    rubric = grading_task.rubric
    assert rubric.persisted?
    assert_equal "Test Assignment Rubric", rubric.title

    # Verify raw rubric
    raw_rubric = rubric.raw_rubric
    assert raw_rubric.persisted?
    assert_equal "Content: 40%, Structure: 30%, Grammar: 30%", raw_rubric.content
  end

  test "orchestrates creation of grading task with feedback tone" do
    # Setup
    user = users(:teacher)

    # Create a valid request with feedback tone
    request = GradingTaskKickOffRequest.new(
      user: user,
      feedback_tone: "critical",
      rubric_raw_text: "Content: 40%, Structure: 30%, Grammar: 30%",
      assignment_prompt_title: "Test Assignment",
      assignment_prompt_subject: "English",
      assignment_prompt_grade_level: "10",
      assignment_prompt_word_count: "500",
      assignment_prompt_content: "Write an essay about climate change.",
      document_data: []
    )

    # Exercise
    grading_task = GradingTask::KickOffService.call(request)

    # Verify
    assert grading_task.persisted?
    assert_equal user, grading_task.user
    assert_equal "created", grading_task.status
    assert_equal "critical", grading_task.feedback_tone

    # Verify assignment prompt
    assignment_prompt = grading_task.assignment_prompt
    assert assignment_prompt.persisted?
    assert_equal "Test Assignment", assignment_prompt.title
    assert_equal "English", assignment_prompt.subject

    # Verify rubric
    rubric = grading_task.rubric
    assert rubric.persisted?
    assert_equal "Test Assignment Rubric", rubric.title

    # Verify raw rubric
    raw_rubric = rubric.raw_rubric
    assert raw_rubric.persisted?
    assert_equal "Content: 40%, Structure: 30%, Grammar: 30%", raw_rubric.content
  end

  test "raises error when request is invalid" do
    # Setup - invalid request (missing required fields)
    invalid_request = GradingTaskKickOffRequest.new

    # Exercise & Verify
    assert_raises(GradingTask::KickOffService::InvalidRequestError) do
      GradingTask::KickOffService.call(invalid_request)
    end
  end

  test "raises error when request is not a GradingTaskKickOffRequest" do
    # Exercise & Verify
    assert_raises(GradingTask::KickOffService::InvalidRequestError) do
      GradingTask::KickOffService.call("not a request object")
    end
  end
end
