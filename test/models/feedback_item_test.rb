require "test_helper"

class FeedbackItemTest < ActiveSupport::TestCase
  def setup
    @student_work = student_works(:one)
    @feedback_item = feedback_items(:strength_1) # Use fixture
  end

  test "invalid without feedbackable" do
    item = FeedbackItem.new(title: "T", description: "D", kind: :strength)
    assert_not item.valid?
    assert_not_empty item.errors[:feedbackable]
  end

  test "invalid without title" do
    item = FeedbackItem.new(feedbackable: @student_work, description: "D", kind: :strength)
    assert_not item.valid?
    assert_not_empty item.errors[:title]
  end

  test "invalid without description" do
    item = FeedbackItem.new(feedbackable: @student_work, title: "T", kind: :strength)
    assert_not item.valid?
    assert_not_empty item.errors[:description]
  end

  test "invalid without kind" do # Renamed from feedback_type
    item = FeedbackItem.new(feedbackable: @student_work, title: "T", description: "D")
    assert_not item.valid?
    assert_not_empty item.errors[:kind] # Check :kind
  end

  test "valid feedback item" do
    # Use fixture
    assert @feedback_item.valid?
  end

  test "belongs to feedbackable (polymorphic)" do
    # Use fixture for assertion
    assert_respond_to @feedback_item, :feedbackable
    assert_equal @student_work, @feedback_item.feedbackable
  end

  test "has kind enum" do # Renamed from feedback_type
    assert_respond_to @feedback_item, :kind # Check :kind attribute
    assert_respond_to @feedback_item, :strength?
    assert_respond_to @feedback_item, :opportunity?

    # Test fixture kind
    assert @feedback_item.strength?
    assert_not @feedback_item.opportunity?

    # Test changing kind
    opportunity_item = feedback_items(:opportunity_1)
    assert opportunity_item.opportunity?
    assert_not opportunity_item.strength?
  end

  test "has prefix id" do
    # Use fixture for assertion
    assert_respond_to @feedback_item, :prefix_id
    assert @feedback_item.prefix_id.starts_with?("fbk_")
    # Unskip the test
    # skip "Prefix ID test requires model and table to exist."
  end
end
