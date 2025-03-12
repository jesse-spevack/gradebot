# frozen_string_literal: true

require "test_helper"

module Admin
  class JobMonitoringControllerTest < ActionDispatch::IntegrationTest
    setup do
      @admin_user = users(:admin)
      @regular_user = users(:teacher)

      # Create sessions for testing
      @admin_session = sessions(:active_session)
      @admin_session.update!(user: @admin_user)

      @regular_session = sessions(:expired_session)
      @regular_session.update!(user: @regular_user)
    end

    test "should redirect non-admin users" do
      # Mock authentication for regular user
      Current.stubs(:user).returns(@regular_user)
      Current.stubs(:session).returns(@regular_session)

      get admin_job_monitoring_index_path
      assert_redirected_to root_path
      assert_equal "You do not have permission to access that page.", flash[:alert]
    end
  end
end
