require "test_helper"

class StudentWorkCriterionLevelTest < ActiveSupport::TestCase
  def setup
    @student_work_one = student_works(:one)
    @student_work_two = student_works(:two)
    @criterion_1 = criteria(:valid_criterion_1)
    @level_1_1 = levels(:clarity_excellent)
    @level_1_2 = levels(:clarity_good)
    @criterion_2 = criteria(:valid_criterion_2)
    @level_2_1 = levels(:content_excellent)

    # Load fixtures into instance variables for clarity
    @swcl_one = student_work_criterion_levels(:one) # sw:one, crit:1, lvl:1_1
    @swcl_two = student_work_criterion_levels(:two) # sw:one, crit:2, lvl:2_1
    @swcl_three = student_work_criterion_levels(:three) # sw:two, crit:1, lvl:1_2
  end

  test "valid instance from fixture" do
    assert @swcl_one.valid?
    assert @swcl_two.valid?
    assert @swcl_three.valid?
  end

  test "invalid without student_work" do
    instance = StudentWorkCriterionLevel.new(criterion: @criterion_1, level: @level_1_1)
    assert_not instance.valid?
    assert_not_empty instance.errors[:student_work]
  end

  test "invalid without criterion" do
    instance = StudentWorkCriterionLevel.new(student_work: @student_work_one, level: @level_1_1)
    assert_not instance.valid?
    assert_not_empty instance.errors[:criterion]
  end

  test "invalid without level" do
    instance = StudentWorkCriterionLevel.new(student_work: @student_work_one, criterion: @criterion_1)
    assert_not instance.valid?
    assert_not_empty instance.errors[:level]
  end

  test "valid without explanation" do
    # Test by modifying an existing valid fixture instance
    @swcl_one.explanation = nil
    assert @swcl_one.valid?, "Should be valid without explanation"
  end

  test "uniqueness validation scoped to student_work and criterion" do
    # Fixture :one already exists: student_work: one, criterion: 1

    # Attempt to create a duplicate (same student_work and criterion as :one)
    duplicate_instance = StudentWorkCriterionLevel.new(
      student_work: @student_work_one, # same as :one fixture
      criterion: @criterion_1,     # same as :one fixture
      level: @level_1_2           # Different level, still fails uniqueness
    )
    assert_not duplicate_instance.valid?, "Should be invalid due to uniqueness constraint"
    assert_includes duplicate_instance.errors[:criterion_id], "has already been evaluated for this student work"

    # Check validity of existing fixtures which prove the scope works
    assert @swcl_one.valid?, "Fixture one (sw:1, crit:1) should be valid."
    assert @swcl_two.valid?, "Fixture two (sw:1, crit:2) should be valid (diff criterion)."
    assert @swcl_three.valid?, "Fixture three (sw:2, crit:1) should be valid (diff student work)."
  end

  test "associations" do
    assert_respond_to @swcl_one, :student_work
    assert_respond_to @swcl_one, :criterion
    assert_respond_to @swcl_one, :level
    assert_equal @student_work_one, @swcl_one.student_work
    assert_equal @criterion_1, @swcl_one.criterion
    assert_equal @level_1_1, @swcl_one.level
  end

  test "has prefix id" do
    assert_respond_to @swcl_one, :prefix_id
    assert @swcl_one.prefix_id.starts_with?("swcl_")
  end
end
