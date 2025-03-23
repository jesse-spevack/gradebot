require "test_helper"

class StudentSubmission::GradeFormatterServiceTest < ActiveSupport::TestCase
  setup do
    # Create a mock submission instead of using fixture
    @student_submission = student_submissions(:pending_submission)
    @document_content = "This is a test document with sample content for grading."

    @grading_response = GradingResponse.new(
      feedback: "This is excellent work with clear arguments!",
      strengths: [ "Clear thesis", "Good structure", "Effective arguments" ],
      opportunities: [ "Add more sources", "Improve conclusion" ],
      overall_grade: "A-",
      rubric_scores: {
        "Content" => 38,
        "Structure" => 28,
        "Grammar" => 29
      },
      question: "How did you choose minecraft as your favorite game?",
      summary: "Student wrote about minecraft as their favorite game because it is a fun game to play with friends."
    )

    @formatter = StudentSubmission::GradeFormatterService.new(
      grading_response: @grading_response,
      document_content: @document_content,
      student_submission: @student_submission
    )
  end

  test "initializes with grading response, document content and submission" do
    assert_equal @grading_response, @formatter.instance_variable_get(:@grading_response)
    assert_equal @document_content, @formatter.instance_variable_get(:@document_content)
    assert_equal @student_submission, @formatter.instance_variable_get(:@student_submission)
  end

  test "formats array attributes correctly" do
    strengths_formatted = @formatter.send(:format_array_attribute, @grading_response.strengths)
    opportunities_formatted = @formatter.send(:format_array_attribute, @grading_response.opportunities)

    assert_equal "- Clear thesis\n- Good structure\n- Effective arguments", strengths_formatted
    assert_equal "- Add more sources\n- Improve conclusion", opportunities_formatted
  end

  test "handles empty array attributes" do
    @grading_response = GradingResponse.new(
      feedback: "This is excellent work with clear arguments!",
      strengths: [],
      opportunities: [ "Add more sources", "Improve conclusion" ],
      overall_grade: "A-",
      rubric_scores: {
        "Content" => 38,
        "Structure" => 28,
        "Grammar" => 29
      },
      question: "How did you choose minecraft as your favorite game?",
      summary: "Student wrote about minecraft as their favorite game because it is a fun game to play with friends."
    )

    result = @formatter.send(:format_array_attribute, @grading_response.strengths)

    assert_equal "", result
  end

  test "handles string attributes" do
    # Setup
    string_attribute = "Already formatted string"

    # Exercise
    result = @formatter.send(:format_array_attribute, string_attribute)

    # Verify
    assert_equal string_attribute, result
  end

  test "builds metadata correctly" do
    metadata = @formatter.send(:build_metadata)

    assert_equal "Document doc123", metadata[:doc_title]
    assert metadata[:processing_time]
    assert_equal 10, metadata[:word_count]
  end

  test "handles nil document title" do
    @student_submission.stubs(:document_title).returns(nil)
    @student_submission.stubs(:metadata).returns({})

    metadata = @formatter.send(:build_metadata)

    assert_equal "Untitled Document", metadata[:doc_title]
  end

  test "format_for_storage returns complete attributes hash" do
    @student_submission.stubs(:document_title).returns("Test Essay")
    @student_submission.stubs(:metadata).returns({})
    Time.stubs(:current).returns(Time.parse("2023-01-01 12:00:00"))
    @student_submission.stubs(:updated_at).returns(Time.parse("2023-01-01 11:55:00"))

    attributes = @formatter.format_for_storage

    assert_equal "This is excellent work with clear arguments!", attributes[:feedback]
    assert_equal "- Clear thesis\n- Good structure\n- Effective arguments", attributes[:strengths]
    assert_equal "- Add more sources\n- Improve conclusion", attributes[:opportunities]
    assert_equal "A-", attributes[:overall_grade]
    assert_equal @grading_response.rubric_scores.to_json, attributes[:rubric_scores]

    assert_equal "Test Essay", attributes[:metadata][:doc_title]
    assert_equal 5.minutes, attributes[:metadata][:processing_time]
    assert_equal 10, attributes[:metadata][:word_count]
  end
end
