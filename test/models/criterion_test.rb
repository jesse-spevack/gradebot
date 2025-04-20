require "test_helper"

class CriterionTest < ActiveSupport::TestCase
  test "valid criterion with all attributes" do
    # Setup
    criterion = Criterion.new(
      rubric: rubrics(:essay_rubric),
      title: "Content Quality",
      description: "Evaluates the depth and quality of content",
      points: 25,
      position: 0
    )

    # Exercise & Verify
    assert criterion.valid?
  end

  test "invalid without title" do
    # Setup
    criterion = Criterion.new(
      rubric: rubrics(:essay_rubric),
      description: "Evaluates the depth and quality of content",
      points: 25,
      position: 1
    )

    # Exercise & Verify
    assert_not criterion.valid?
    assert_includes criterion.errors[:title], "can't be blank"
  end

  test "invalid without rubric" do
    # Setup
    criterion = Criterion.new(
      title: "Content Quality",
      description: "Evaluates the depth and quality of content",
      points: 25,
      position: 1
    )

    # Exercise & Verify
    assert_not criterion.valid?
    assert_includes criterion.errors[:rubric], "must exist"
  end

  test "invalid without points" do
    # Setup
    criterion = Criterion.new(
      rubric: rubrics(:essay_rubric),
      title: "Content Quality",
      description: "Evaluates the depth and quality of content",
      position: 1
    )

    # Exercise & Verify
    assert_not criterion.valid?
    assert_includes criterion.errors[:points], "can't be blank"
  end

  test "invalid without position" do
    # Setup
    criterion = Criterion.new(
      rubric: rubrics(:essay_rubric),
      title: "Content Quality",
      description: "Evaluates the depth and quality of content",
      points: 25
    )

    # Exercise & Verify
    assert_not criterion.valid?
    assert_includes criterion.errors[:position], "can't be blank"
  end

  test "position must be unique within a rubric" do
    # Setup
    existing = criteria(:content_criterion)
    duplicate = Criterion.new(
      rubric: existing.rubric,
      title: "Different Title",
      description: "Different description",
      points: 25,
      position: existing.position
    )

    # Exercise & Verify
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:position], "has already been taken"
  end

  test "has many levels" do
    # Setup
    criterion = criteria(:content_criterion)

    # Exercise & Verify
    assert_respond_to criterion, :levels
  end

  test "belongs to rubric" do
    # Setup
    criterion = criteria(:content_criterion)

    # Exercise & Verify
    assert_respond_to criterion, :rubric
  end

  test "destroys associated levels when deleted" do
    # Setup
    criterion = criteria(:content_criterion)
    level_count = criterion.levels.count
    assert level_count > 0, "Test requires at least one level"

    # Exercise
    criterion.destroy

    # Verify
    assert_equal 0, Level.where(criterion_id: criterion.id).count
  end
end
