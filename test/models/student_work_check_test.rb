require "test_helper"

class StudentWorkCheckTest < ActiveSupport::TestCase
  def setup
    @student_work = student_works(:one)
    @check = student_work_checks(:llm_check_sw_one) # Use fixture
  end

  test "invalid without student_work" do
    check = StudentWorkCheck.new(check_type: :llm_generated, score: 50)
    assert_not check.valid?
    assert_not_empty check.errors[:student_work]
  end

  test "invalid without check_type" do
    check = StudentWorkCheck.new(student_work: @student_work, score: 50)
    assert_not check.valid?
    assert_not_empty check.errors[:check_type]
  end

  test "invalid without score" do
    check = StudentWorkCheck.new(student_work: @student_work, check_type: :llm_generated)
    assert_not check.valid?
    assert_not_empty check.errors[:score]
  end

  test "invalid score below 0" do
    check = StudentWorkCheck.new(student_work: @student_work, check_type: :llm_generated, score: -1)
    assert_not check.valid?
    assert_includes check.errors[:score], "must be greater than or equal to 0"
  end

  test "invalid score above 100" do
    check = StudentWorkCheck.new(student_work: @student_work, check_type: :llm_generated, score: 101)
    assert_not check.valid?
    assert_includes check.errors[:score], "must be less than or equal to 100"
  end

  test "invalid writing_grade_level score below 1" do
    check = StudentWorkCheck.new(student_work: @student_work, check_type: :writing_grade_level, score: 0)
    assert_not check.valid?
    assert_includes check.errors[:score], "must be between 1 and 12 for writing grade level check type"
  end

  test "invalid writing_grade_level score above 12" do
    check = StudentWorkCheck.new(student_work: @student_work, check_type: :writing_grade_level, score: 13)
    assert_not check.valid?
    assert_includes check.errors[:score], "must be between 1 and 12 for writing grade level check type"
  end

  test "valid writing_grade_level score at 1" do
    check = StudentWorkCheck.new(student_work: @student_work, check_type: :writing_grade_level, score: 1)
    assert check.valid?, "Score of 1 should be valid for writing_grade_level. Errors: #{check.errors.full_messages.join(", ")}"
  end

  test "valid writing_grade_level score at 12" do
    check = StudentWorkCheck.new(student_work: @student_work, check_type: :writing_grade_level, score: 12)
    assert check.valid?, "Score of 12 should be valid for writing_grade_level. Errors: #{check.errors.full_messages.join(", ")}"
  end

  test "valid writing_grade_level score between 1 and 12" do
    check = student_work_checks(:grade_level_sw_one) # Uses score: 8
    assert check.valid?, "Fixture grade_level_sw_one (score 8) should be valid"
  end

  test "score validation does not interfere with other check_types" do
    # Score 13 is invalid for writing_grade_level, but valid for others
    check = StudentWorkCheck.new(student_work: @student_work, check_type: :llm_generated, score: 13)
    assert check.valid?, "Score 13 should be valid for llm_generated. Errors: #{check.errors.full_messages.join(", ")}"

    check = StudentWorkCheck.new(student_work: @student_work, check_type: :plagiarism, score: 0)
    assert check.valid?, "Score 0 should be valid for plagiarism. Errors: #{check.errors.full_messages.join(", ")}"
  end

  test "valid check instance using fixture" do
    assert @check.valid?, "Fixture llm_check_sw_one should be valid"
    assert student_work_checks(:grade_level_sw_one).valid?
    assert student_work_checks(:plagiarism_sw_one).valid?
  end

  test "valid check without explanation" do
    check = StudentWorkCheck.new(student_work: @student_work, check_type: :llm_generated, score: 95)
    assert check.valid?
  end

  test "belongs to student_work" do
    assert_respond_to @check, :student_work
    assert_equal @student_work, @check.student_work
  end

  test "has check_type enum" do
    assert_respond_to @check, :check_type
    assert_respond_to @check, :llm_generated?
    assert_respond_to @check, :writing_grade_level?
    assert_respond_to @check, :plagiarism?

    assert @check.llm_generated?
    assert_not @check.writing_grade_level?

    grade_check = student_work_checks(:grade_level_sw_one)
    assert grade_check.writing_grade_level?
    assert_not grade_check.plagiarism?
  end

  test "has prefix id" do
    assert_respond_to @check, :prefix_id
    assert @check.prefix_id.starts_with?("chk_")
  end
end
