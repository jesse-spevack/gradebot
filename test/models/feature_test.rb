require "test_helper"

class FeatureTest < ActiveSupport::TestCase
  include ActionDispatch::TestProcess::FixtureFile

  test "should be valid with title and description" do
    # Setup
    feature = Feature.new(title: "Amazing Feature", description: "This feature does amazing things.")

    # Exercise & Verify
    assert feature.valid?
  end

  test "should be invalid without title" do
    # Setup
    feature = Feature.new(description: "This feature does amazing things.")

    # Exercise & Verify
    assert_not feature.valid?
    assert_includes feature.errors[:title], "can't be blank"
  end

  test "should be invalid without description" do
    # Setup
    feature = Feature.new(title: "Amazing Feature")

    # Exercise & Verify
    assert_not feature.valid?
    assert_includes feature.errors[:description], "can't be blank"
  end

  test "should allow attaching a picture" do
    # Setup
    feature = Feature.new(title: "Feature with Picture", description: "Look at this attached picture.")
    dummy_file = fixture_file_upload("sample.png", "image/png") # Use relative path within fixtures/files

    # Exercise
    feature.image.attach(dummy_file)

    # Verify
    assert feature.image.attached?
  end
end
