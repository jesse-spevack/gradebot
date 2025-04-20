require "test_helper"

class LevelTest < ActiveSupport::TestCase
  def setup
    @criterion = criteria(:valid_criterion_1)
    @level = levels(:clarity_excellent) # Use a valid fixture
  end

  test "invalid without title" do
    # Test validation by creating an invalid object directly
    level = Level.new(description: "No title", position: 3, criterion: @criterion)
    assert_not level.valid?, "Level should be invalid without a title"
    assert_not_empty level.errors[:title], "Should have an error message for missing title"
  end

  test "valid level" do
    # Use a valid fixture
    assert @level.valid?, "Level fixture should be valid"
  end

  test "belongs to criterion" do
    # Assert the actual association using the fixture
    assert_respond_to @level, :criterion
    assert_equal @criterion, @level.criterion, "Level should belong to the correct criterion"
  end

  test "has position attribute" do
    assert_respond_to @level, :position, "Level should respond to position"
    assert_equal 0, @level.position # Check position from fixture (clarity_excellent is 0)
  end

  test "has prefix id" do
    # Now we can assert the prefix ID generation
    assert_not_nil @level.id, "Level fixture should have an ID"
    assert_respond_to @level, :prefix_id, "Level should respond to prefix_id"
    assert_not_nil @level.prefix_id, "Level fixture should have a prefix_id"
    assert @level.prefix_id.starts_with?("lvl_"), "Level prefix_id should start with 'lvl_'"
  end
end
