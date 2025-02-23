require "test_helper"

class HomeTest < ActionDispatch::IntegrationTest
  test "visiting the home page" do
    get root_path
    assert_response :success
    assert_select "h1", text: "GradeB🤖t"
    assert_select "form"
    assert_select "input[type=email]"
    assert_select "input[type=submit]"
  end

  test "signing up with valid email" do
    assert_difference "EmailSignup.count" do
      post email_signups_path, params: {
        email_signup: { email: "teacher@gmail.com" }
      }
    end
    assert_redirected_to root_path
    follow_redirect!
    assert_select ".text-green-600", text: "✓"
  end

  test "signing up with invalid email" do
    assert_no_difference "EmailSignup.count" do
      post email_signups_path, params: {
        email_signup: { email: "invalid-email" }
      }
    end
    assert_response :unprocessable_entity
    assert_select ".text-red-600"
  end
end
