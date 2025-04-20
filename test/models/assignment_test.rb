require "test_helper"

class AssignmentTest < ActiveSupport::TestCase
  # Helper method to get valid attributes, referencing the existing valid fixture
  def valid_attributes
    assignments(:valid_assignment).attributes.except("id", "created_at", "updated_at")
  end

  test "valid assignment" do
    assignment = assignments(:valid_assignment)
    assert assignment.valid?, assignment.errors.full_messages.inspect
  end

  test "invalid without title" do
    # Setup
    attrs = valid_attributes.merge(title: nil)
    assignment = Assignment.new(attrs)
    # Exercise & Verify
    assert_not assignment.valid?
    assert_includes assignment.errors[:title], "can't be blank"
  end

  test "invalid without subject" do
    # Setup
    attrs = valid_attributes.merge(subject: nil)
    assignment = Assignment.new(attrs)
    # Exercise & Verify
    assert_not assignment.valid?, "Assignment should be invalid without a subject"
    assert_includes assignment.errors[:subject], "can't be blank"
  end

  test "invalid without grade_level" do
    # Setup
    attrs = valid_attributes.merge(grade_level: nil)
    assignment = Assignment.new(attrs)
    # Exercise & Verify
    assert_not assignment.valid?, "Assignment should be invalid without a grade_level"
    assert_includes assignment.errors[:grade_level], "can't be blank"
  end

  test "belongs_to user" do
    assignment = assignments(:valid_assignment)
    assert_respond_to assignment, :user
    assert_instance_of User, assignment.user
  end

  test "has_one rubric" do
    assignment = assignments(:valid_assignment)
    assert_respond_to assignment, :rubric
    # Further association tests (like creation/destruction) will be added when Rubric model exists
  end

  test "has_many student_works" do
    assignment = assignments(:valid_assignment)
    assert_respond_to assignment, :student_works
    # Further association tests will be added when StudentWork model exists
  end

  test "has_one assignment_summary" do
    assignment = assignments(:valid_assignment)
    assert_respond_to assignment, :assignment_summary
    # Further association tests will be added when AssignmentSummary model exists
  end

  test "raw_rubric_text can be nil" do
    # Setup
    assignment = Assignment.new(valid_attributes.merge(raw_rubric_text: nil))
    # Exercise & Verify
    assert assignment.valid?, "Assignment should be valid with nil raw_rubric_text"
  end

  test "total_processing_milliseconds can be nil" do
    # Setup
    assignment = Assignment.new(valid_attributes.merge(total_processing_milliseconds: nil))
    # Exercise & Verify
    assert assignment.valid?, "Assignment should be valid with nil total_processing_milliseconds"
  end
end
