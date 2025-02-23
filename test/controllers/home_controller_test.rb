require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get root_path
    assert_response :success
  end

  test "should create email signup and show flash in hero form" do
    assert_difference("EmailSignup.count") do
      post email_signups_path, params: {
        email_signup: {
          email: "test@example.com",
          form_id: "hero-form"
        }
      }
    end

    assert_redirected_to root_path
    follow_redirect!

    # Flash message should be present
    assert_equal "Thanks for signing up! We'll keep you posted.", flash[:notice]
    assert_equal "hero-form", flash[:target_form]

    # Flash should appear in hero form but not footer form
    assert_select "#hero-form .text-green-600", "Thanks for signing up! We'll keep you posted."
    assert_select "#footer-form .text-green-600", false
  end

  test "should create email signup and show flash in footer form" do
    assert_difference("EmailSignup.count") do
      post email_signups_path, params: {
        email_signup: {
          email: "test@example.com",
          form_id: "footer-form"
        }
      }
    end

    assert_redirected_to root_path
    follow_redirect!

    # Flash message should be present
    assert_equal "Thanks for signing up! We'll keep you posted.", flash[:notice]
    assert_equal "footer-form", flash[:target_form]

    # Flash should appear in footer form but not hero form
    assert_select "#footer-form .text-green-600", "Thanks for signing up! We'll keep you posted."
    assert_select "#hero-form .text-green-600", false
  end
end
