require "test_helper"

class GradeFormatterServiceTest < ActiveSupport::TestCase
  setup do
    # Create a mock submission instead of using fixture
    @submission = mock("StudentSubmission")
    @document_content = "This is a test document with sample content for grading."

    # Create mock grading result
    @grading_result = mock("GradingResponse")
    @grading_result.stubs(:feedback).returns("This is excellent work with clear arguments!")
    @grading_result.stubs(:strengths).returns([ "Clear thesis", "Good structure", "Effective arguments" ])
    @grading_result.stubs(:opportunities).returns([ "Add more sources", "Improve conclusion" ])
    @grading_result.stubs(:overall_grade).returns("A-")
    @grading_result.stubs(:rubric_scores).returns({
      "Content" => 38,
      "Structure" => 28,
      "Grammar" => 29
    })

    # Setup submission mock with default values
    @submission.stubs(:id).returns(123)
    @submission.stubs(:document_title).returns("Test Essay")
    @submission.stubs(:metadata).returns({})
    @submission.stubs(:updated_at).returns(Time.current - 60.seconds)

    # Initialize service
    @formatter = GradeFormatterService.new(@grading_result, @document_content, @submission)
  end

  test "initializes with grading result, document content and submission" do
    # Verify
    assert_equal @grading_result, @formatter.instance_variable_get(:@result)
    assert_equal @document_content, @formatter.instance_variable_get(:@document_content)
    assert_equal @submission, @formatter.instance_variable_get(:@submission)
  end

  test "formats array attributes correctly" do
    # Exercise
    strengths_formatted = @formatter.send(:format_array_attribute, @grading_result.strengths)
    opportunities_formatted = @formatter.send(:format_array_attribute, @grading_result.opportunities)

    # Verify
    assert_equal "- Clear thesis\n- Good structure\n- Effective arguments", strengths_formatted
    assert_equal "- Add more sources\n- Improve conclusion", opportunities_formatted
  end

  test "handles empty array attributes" do
    # Setup
    @grading_result.stubs(:strengths).returns([])

    # Exercise
    result = @formatter.send(:format_array_attribute, @grading_result.strengths)

    # Verify
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
    # Setup
    time_now = Time.current
    Time.stubs(:current).returns(time_now)
    @submission.stubs(:updated_at).returns(time_now - 60.seconds)
    @submission.stubs(:document_title).returns("Test Essay")
    @submission.stubs(:metadata).returns({ "existing_key" => "existing_value" })

    # Exercise
    metadata = @formatter.send(:build_metadata)

    # Verify
    assert_equal "Test Essay", metadata[:doc_title]
    assert_equal 60.0, metadata[:processing_time]
    assert_equal 10, metadata[:word_count] # Based on our @document_content
    assert_equal "existing_value", metadata["existing_key"]
  end

  test "handles nil document title" do
    # Setup
    @submission.stubs(:document_title).returns(nil)
    @submission.stubs(:metadata).returns({})

    # Exercise
    metadata = @formatter.send(:build_metadata)

    # Verify
    assert_equal "Untitled Document", metadata[:doc_title]
  end

  test "format_for_storage returns complete attributes hash" do
    # Setup
    @submission.stubs(:document_title).returns("Test Essay")
    @submission.stubs(:metadata).returns({})
    Time.stubs(:current).returns(Time.parse("2023-01-01 12:00:00"))
    @submission.stubs(:updated_at).returns(Time.parse("2023-01-01 11:55:00"))

    # Exercise
    attributes = @formatter.format_for_storage

    # Verify
    assert_equal "This is excellent work with clear arguments!", attributes[:feedback]
    assert_equal "- Clear thesis\n- Good structure\n- Effective arguments", attributes[:strengths]
    assert_equal "- Add more sources\n- Improve conclusion", attributes[:opportunities]
    assert_equal "A-", attributes[:overall_grade]
    assert_equal @grading_result.rubric_scores.to_json, attributes[:rubric_scores]

    # Check metadata
    assert_equal "Test Essay", attributes[:metadata][:doc_title]
    assert_equal 300.0, attributes[:metadata][:processing_time] # 5 minutes = 300 seconds
    assert_equal 10, attributes[:metadata][:word_count]
  end
end
