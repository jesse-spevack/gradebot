require "test_helper"

class Rubric::CreationServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:teacher)
  end

  test "creates a rubric with valid parameters" do
    rubric = Rubric::CreationService.call(
      user: @user,
      title: "Test Assignment"
    )

    assert rubric.persisted?
    assert_equal "Test Assignment Rubric", rubric.title
    assert_equal @user, rubric.user
    assert_equal 100, rubric.total_points
    assert_equal "pending", rubric.status
  end


  test "raises error when user is missing" do
    assert_raises ActiveRecord::RecordInvalid do
      Rubric::CreationService.call(
        title: "Test Assignment",
        user: nil
      )
    end
  end
end
