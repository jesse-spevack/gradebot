# frozen_string_literal: true

require "test_helper"
require "rake"

class AdminSeederTest < ActiveSupport::TestCase
  def setup
    Gradebot::Application.load_tasks if Rake::Task.tasks.empty?
    @admin_email = "admin@example.com"
    ENV["ADMIN_EMAIL"] = @admin_email

    # Create a user with the admin email if it doesn't exist
    User.find_or_create_by!(
      email: @admin_email,
      name: "Admin User",
      google_uid: "admin_google_uid"
    )

    # Reset the task to allow it to be called multiple times
    Rake::Task["admin:seed"].reenable
  end

  def teardown
    ENV.delete("ADMIN_EMAIL")
  end

  test "sets admin flag for user with matching email" do
    Rake::Task["admin:seed"].invoke

    admin_user = User.find_by(email: @admin_email)
    assert admin_user.admin?, "User with admin email should have admin flag set to true"
  end

  test "does not change admin flag for other users" do
    regular_user = users(:teacher)
    regular_user.update!(admin: false)

    Rake::Task["admin:seed"].invoke
    Rake::Task["admin:seed"].reenable

    regular_user.reload
    assert_not regular_user.admin?, "Other users should not have admin flag changed"
  end

  test "raises error when ADMIN_EMAIL is not set" do
    ENV.delete("ADMIN_EMAIL")
    Rake::Task["admin:seed"].reenable

    error = assert_raises(RuntimeError) do
      Rake::Task["admin:seed"].invoke
    end

    assert_equal "ADMIN_EMAIL environment variable must be set", error.message
  end

  test "raises error when user with admin email does not exist" do
    ENV["ADMIN_EMAIL"] = "nonexistent@example.com"
    Rake::Task["admin:seed"].reenable

    error = assert_raises(RuntimeError) do
      Rake::Task["admin:seed"].invoke
    end

    assert_equal "User with email 'nonexistent@example.com' not found", error.message
  end
end
