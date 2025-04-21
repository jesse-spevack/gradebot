require "test_helper"

class AssignmentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:teacher)
    @assignment = assignments(:valid_assignment)
    @other_user = users(:teacher2)
    @other_assignment = assignments(:assignment_for_other_user)
  end

  # Authentication tests - these verify that unauthenticated users are redirected
  test "should redirect index when not authenticated" do
    get assignments_url
    assert_redirected_to new_session_url
  end

  test "should redirect new when not authenticated" do
    get new_assignment_url
    assert_redirected_to new_session_url
  end

  test "should redirect create when not authenticated" do
    post assignments_url, params: {
      assignment: { title: "Test Assignment" }
    }
    assert_redirected_to new_session_url
  end

  test "should redirect show when not authenticated" do
    get assignment_url(@assignment)
    assert_redirected_to new_session_url
  end

  test "should redirect destroy when not authenticated" do
    delete assignment_url(@assignment)
    assert_redirected_to new_session_url
  end
end
