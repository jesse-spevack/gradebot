require "test_helper"

class HomeTest < ActionDispatch::IntegrationTest
  test "home page and email signup flow" do
    # Check home page elements
    get root_path
    assert_response :success
    assert_select "form"
    assert_select "input[type=email]"

    # Test invalid email signup
    assert_no_difference "EmailSignup.count" do
      post email_signups_path, params: { email_signup: { email: "invalid-email" } }
    end
    assert_response :unprocessable_entity
    assert_select ".text-red-600"

    # Test valid email signup
    assert_difference "EmailSignup.count" do
      post email_signups_path, params: { email_signup: { email: "teacher@gmail.com" } }
    end
    assert_redirected_to root_path
    follow_redirect!
    assert_select ".text-green-600", text: "✓"
  end
end
