require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get root_path
    assert_response :success
  end

  test "should create email signup and show flash in correct form" do
    [ "hero-form", "footer-form" ].each_with_index do |form_id, index|
      assert_difference("EmailSignup.count") do
        post email_signups_path, params: {
          email_signup: {
            email: "test#{index + 1}@example.com",
            form_id: form_id
          }
        }
      end

      assert_redirected_to root_path
      follow_redirect!

      # Flash message should be present
      assert_equal "Thanks for signing up! We'll keep you posted.", flash[:notice]
      assert_equal form_id, flash[:target_form]

      # Flash should appear only in the correct form
      assert_select "##{form_id} .text-green-600", "Thanks for signing up! We'll keep you posted."
      assert_select "##{form_id == 'hero-form' ? 'footer-form' : 'hero-form'} .text-green-600", false
    end
  end
end
