require "test_helper"

class LevelTest < ActiveSupport::TestCase
  test "valid level with all attributes" do
    # Setup
    level = Level.new(
      criterion: criteria(:content_criterion),
      title: "Excellent",
      description: "Demonstrates exceptional understanding",
      points: 25,
      position: 0
    )

    # Exercise & Verify
    assert level.valid?
  end

  test "invalid without title" do
    # Setup
    level = Level.new(
      criterion: criteria(:content_criterion),
      description: "Demonstrates exceptional understanding",
      points: 25,
      position: 1
    )

    # Exercise & Verify
    assert_not level.valid?
    assert_includes level.errors[:title], "can't be blank"
  end

  test "invalid without criterion" do
    # Setup
    level = Level.new(
      title: "Excellent",
      description: "Demonstrates exceptional understanding",
      points: 25,
      position: 1
    )

    # Exercise & Verify
    assert_not level.valid?
    assert_includes level.errors[:criterion], "must exist"
  end

  test "invalid without points" do
    # Setup
    level = Level.new(
      criterion: criteria(:content_criterion),
      title: "Excellent",
      description: "Demonstrates exceptional understanding",
      position: 1
    )

    # Exercise & Verify
    assert_not level.valid?
    assert_includes level.errors[:points], "can't be blank"
  end

  test "invalid without position" do
    # Setup
    level = Level.new(
      criterion: criteria(:content_criterion),
      title: "Excellent",
      description: "Demonstrates exceptional understanding",
      points: 25
    )

    # Exercise & Verify
    assert_not level.valid?
    assert_includes level.errors[:position], "can't be blank"
  end

  test "position must be unique within a criterion" do
    # Setup
    existing = levels(:excellent_level)
    duplicate = Level.new(
      criterion: existing.criterion,
      title: "Different Title",
      description: "Different description",
      points: 20,
      position: existing.position
    )

    # Exercise & Verify
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:position], "has already been taken"
  end

  test "belongs to criterion" do
    # Setup
    level = levels(:excellent_level)

    # Exercise & Verify
    assert_respond_to level, :criterion
  end

  test "points cannot exceed criterion points" do
    # Setup
    criterion = criteria(:content_criterion)
    level = Level.new(
      criterion: criterion,
      title: "Excellent",
      description: "Demonstrates exceptional understanding",
      points: criterion.points + 1,
      position: 1
    )

    # Exercise & Verify
    assert_not level.valid?
    assert_includes level.errors[:points], "cannot exceed criterion points"
  end
end
