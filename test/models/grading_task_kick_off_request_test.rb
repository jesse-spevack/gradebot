require "test_helper"

class GradingTaskKickOffRequestTest < ActiveSupport::TestCase
  setup do
    @user = users(:teacher)
    @valid_document_data = DocumentDataCollection.new([
      { "id" => "doc1", "name" => "Student 1 Document", "url" => "https://docs.google.com/document/d/doc1" },
      { "id" => "doc2", "name" => "Student 2 Document", "url" => "https://docs.google.com/document/d/doc2" }
    ])
  end

  test "is invalid without required fields" do
    # Create with missing required fields
    request = GradingTaskKickOffRequest.new

    # Should not be valid
    assert_not request.valid?
    assert_includes request.errors[:user], "can't be blank"
    assert_includes request.errors[:assignment_prompt_title], "can't be blank"
    assert_includes request.errors[:assignment_prompt_content], "can't be blank"
    assert_includes request.errors[:rubric_raw_text], "can't be blank"
  end

  test "is valid with all required fields" do
    request = GradingTaskKickOffRequest.new(
      user: @user,
      rubric_raw_text: "Content: 40%, Structure: 30%, Grammar: 30%",
      assignment_prompt_title: "Test Assignment",
      assignment_prompt_content: "Write an essay about climate change.",
      document_data: @valid_document_data
    )

    assert request.valid?
  end

  test "is valid with AI rubric generation and no rubric text" do
    request = GradingTaskKickOffRequest.new(
      user: @user,
      ai_generate_rubric: true,
      rubric_raw_text: nil,
      assignment_prompt_title: "Test Assignment",
      assignment_prompt_content: "Write an essay about climate change.",
      document_data: @valid_document_data
    )

    assert request.valid?
  end

  test "validates feedback_tone is in allowed values" do
    # Create with invalid feedback tone
    request = GradingTaskKickOffRequest.new(
      user: @user,
      rubric_raw_text: "Content: 40%, Structure: 30%, Grammar: 30%",
      assignment_prompt_title: "Test Assignment",
      assignment_prompt_content: "Write an essay about climate change.",
      feedback_tone: "invalid_tone",
      document_data: @valid_document_data
    )

    # Should not be valid
    assert_not request.valid?

    # Update to a valid tone
    request.feedback_tone = "encouraging"
    assert request.valid?

    # Nil is allowed
    request.feedback_tone = nil
    assert request.valid?
  end

  test "validates document_data is valid" do
    # Create with invalid document data
    invalid_collection = DocumentDataCollection.new([
      { "id" => "doc1", "name" => "" } # Missing name and url
    ])

    request = GradingTaskKickOffRequest.new(
      user: @user,
      rubric_raw_text: "Content: 40%, Structure: 30%, Grammar: 30%",
      assignment_prompt_title: "Test Assignment",
      assignment_prompt_content: "Write an essay about climate change.",
      document_data: invalid_collection
    )

    # Should not be valid
    assert_not request.valid?
    assert_includes request.errors[:document_data], "Document 1: Name can't be blank"
    assert_includes request.errors[:document_data], "Document 1: Url can't be blank"

    # Update to valid document data
    request.document_data = @valid_document_data
    assert request.valid?
  end

  test "from_controller_params builds a valid object" do
    # Create mock controller params similar to what we'd get from the form
    controller_params = {
      feedback_tone: "critical",
      rubric_raw_text: "Content: 40%, Structure: 30%, Grammar: 30%",
      assignment_prompt_attributes: {
        title: "Test Assignment",
        subject: "English",
        grade_level: "10",
        word_count: "500",
        content: "Write an essay about climate change.",
        due_date: Date.tomorrow
      }
    }

    # Build from controller params
    request = GradingTaskKickOffRequest.from_controller_params(controller_params, @user, @valid_document_data)

    # Should be valid
    assert request.valid?
    assert_equal @user, request.user
    assert_equal "critical", request.feedback_tone
    assert_equal "Content: 40%, Structure: 30%, Grammar: 30%", request.rubric_raw_text
    assert_equal false, request.ai_generate_rubric
    assert_equal "Test Assignment", request.assignment_prompt_title
    assert_equal "English", request.assignment_prompt_subject
    assert_equal "10", request.assignment_prompt_grade_level
    assert_equal "500", request.assignment_prompt_word_count
    assert_equal "Write an essay about climate change.", request.assignment_prompt_content
    assert_equal Date.tomorrow, request.assignment_prompt_due_date
    assert_instance_of DocumentDataCollection, request.document_data
    assert_equal 2, request.document_data.count
  end

  test "from_controller_params handles AI rubric generation" do
    controller_params = {
      feedback_tone: "encouraging",
      ai_generate_rubric: "1",
      assignment_prompt_attributes: {
        title: "Test Assignment",
        content: "Write an essay about climate change."
      }
    }

    request = GradingTaskKickOffRequest.from_controller_params(controller_params, @user, @valid_document_data)

    assert request.valid?
    assert_equal true, request.ai_generate_rubric
    assert_nil request.rubric_raw_text
  end
end
