require "test_helper"

class StudentSubmissionCheckTest < ActiveSupport::TestCase
  test "valid student_submission_check with all attributes" do
    # Setup
    check = StudentSubmissionCheck.new(
      student_submission: student_submissions(:pending_submission),
      check_type: :plagiarism,
      score: 95,
      reason: "Analyzed content appears to be original work."
    )

    # Exercise & Verify
    assert check.valid?
  end

  test "invalid without student_submission" do
    # Setup
    check = StudentSubmissionCheck.new(
      check_type: :plagiarism,
      score: 95,
      reason: "Analyzed content appears to be original work."
    )

    # Exercise & Verify
    assert_not check.valid?
    assert_includes check.errors[:student_submission], "must exist"
  end

  test "invalid without check_type" do
    # Setup
    check = StudentSubmissionCheck.new(
      student_submission: student_submissions(:pending_submission),
      score: 95,
      reason: "Analyzed content appears to be original work."
    )

    # Exercise & Verify
    assert_not check.valid?
    assert_includes check.errors[:check_type], "can't be blank"
  end

  test "belongs to student_submission" do
    # Setup
    check = student_submission_checks(:plagiarism_check)

    # Exercise & Verify
    assert_respond_to check, :student_submission
  end

  test "check_type enum works correctly" do
    # Setup
    check = StudentSubmissionCheck.new(
      student_submission: student_submissions(:pending_submission),
      check_type: :plagiarism,
      score: 95,
      reason: "Analyzed content appears to be original work."
    )

    # Exercise & Verify
    assert_equal "plagiarism", check.check_type

    # Change to different enum value
    check.check_type = :authenticity
    assert_equal "authenticity", check.check_type
  end

  test "invalid without score" do
    # Setup
    check = StudentSubmissionCheck.new(
      student_submission: student_submissions(:pending_submission),
      check_type: :plagiarism,
      reason: "Analyzed content appears to be original work."
    )

    # Exercise & Verify
    assert_not check.valid?
    assert_includes check.errors[:score], "can't be blank"
  end

  test "invalid without reason" do
    # Setup
    check = StudentSubmissionCheck.new(
      student_submission: student_submissions(:pending_submission),
      check_type: :plagiarism,
      score: 95
    )

    # Exercise & Verify
    assert_not check.valid?
    assert_includes check.errors[:reason], "can't be blank"
  end
end
