require "test_helper"

class StudentWorkTest < ActiveSupport::TestCase
  def setup
    @assignment = assignments(:valid_assignment)
    @student_work = student_works(:one) # Use fixture
  end

  test "invalid without assignment" do
    student_work = StudentWork.new(qualitative_feedback: "Good work")
    assert_not student_work.valid?, "StudentWork should be invalid without an assignment"
    assert_not_empty student_work.errors[:assignment], "Should have error on assignment"
  end

  test "valid student work" do
    # Use fixture
    assert @student_work.valid?, "StudentWork fixture should be valid"
  end

  test "belongs to assignment" do
    # Use fixture for assertion
    assert_respond_to @student_work, :assignment
    assert_equal @assignment, @student_work.assignment
  end

  test "has many feedback_items" do
    assert_respond_to @student_work, :feedback_items
    # Add dependent: :destroy check later if FeedbackItem model exists
  end

  test "has many student_work_checks" do
    assert_respond_to @student_work, :student_work_checks
    # Add dependent: :destroy check later if StudentWorkCheck model exists
  end

  test "has status enum with default pending" do
    # Test default on new record
    new_work = StudentWork.new(assignment: @assignment)
    assert new_work.pending?, "New StudentWork should default to pending status"

    # Test fixture status
    assert @student_work.pending?

    # Test transitions (basic enum functionality)
    @student_work.processing!
    assert @student_work.processing?
    @student_work.completed!
    assert @student_work.completed?
    @student_work.failed!
    assert @student_work.failed?
  end

  test "has prefix id" do
    # Use fixture for assertion
    assert_respond_to @student_work, :prefix_id
    assert @student_work.prefix_id.starts_with?("sw_")
    # Unskip the test
    # skip "Prefix ID test requires model and table to exist."
  end
end
