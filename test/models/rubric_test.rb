require "test_helper"

class RubricTest < ActiveSupport::TestCase
  # Helper method to get valid attributes, referencing the existing valid fixture
  def valid_attributes
    # Ensure assignment association is correctly set up for the new object
    # We clone attributes and explicitly set the assignment object
    attrs = rubrics(:valid_rubric).attributes.except("id", "created_at", "updated_at", "assignment_id")
    attrs[:assignment] = assignments(:valid_assignment)
    attrs
  end

  test "valid rubric" do
    rubric = rubrics(:valid_rubric)
    assert rubric.valid?, rubric.errors.full_messages.inspect
  end

  test "invalid without title" do
    # Setup
    attrs = valid_attributes.merge(title: nil)
    rubric = Rubric.new(attrs)
    # Exercise & Verify
    assert_not rubric.valid?
    assert_includes rubric.errors[:title], "can\'t be blank"
  end

  test "invalid without assignment" do
    # Setup
    attrs = valid_attributes.except(:assignment)
    rubric = Rubric.new(attrs)
    # Exercise & Verify
    assert_not rubric.valid?
    assert_includes rubric.errors[:assignment], "must exist"
  end

  test "description is optional" do
    # Setup
    attrs = valid_attributes.merge(description: nil)
    rubric = Rubric.new(attrs)
    # Exercise & Verify
    assert rubric.valid?, "Rubric should be valid without a description"
  end

  test "belongs_to assignment" do
    rubric = rubrics(:valid_rubric)
    assert_respond_to rubric, :assignment
    assert_instance_of Assignment, rubric.assignment
  end

  test "has_many criteria" do
    rubric = rubrics(:valid_rubric)
    assert_respond_to rubric, :criteria
    # Further association tests will be added when Criterion model exists
  end
end
