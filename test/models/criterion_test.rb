require "test_helper"

class CriterionTest < ActiveSupport::TestCase
  def setup
    @rubric = rubrics(:valid_rubric)
    @criterion = criteria(:valid_criterion_1) # Use a valid fixture
  end

  test "invalid without title" do
    # Test validation by creating an invalid object directly
    criterion = Criterion.new(description: "Test Description", position: 3, rubric: @rubric)
    assert_not criterion.valid?, "Criterion should be invalid without a title"
    assert_not_empty criterion.errors[:title], "Should have an error message for missing title"
  end

  test "valid criterion" do
    # Use a valid fixture
    assert @criterion.valid?, "Criterion fixture should be valid"
  end

  test "belongs to rubric" do
    # Assert the actual association using the fixture
    assert_respond_to @criterion, :rubric
    assert_equal @rubric, @criterion.rubric, "Criterion should belong to the correct rubric"
  end

  test "has many levels" do
    assert_respond_to @criterion, :levels, "Criterion should respond to levels"
    # Further association testing will happen when Level model and fixtures exist
  end

  test "has position attribute" do
    assert_respond_to @criterion, :position, "Criterion should respond to position"
    assert_equal 1, @criterion.position # Check position from fixture
  end

  test "has prefix id" do
    # Now we can assert the prefix ID generation
    assert_not_nil @criterion.prefix_id, "Criterion fixture should have an ID"
    assert @criterion.prefix_id.starts_with?("crit_"), "Criterion ID should start with 'crit_'"
  end
end
