require "test_helper"

class GradingTaskAccessTokenServiceTest < ActiveSupport::TestCase
  setup do
    @user = mock("User")
    @user.stubs(:id).returns(456)

    @grading_task = mock("GradingTask")
    @grading_task.stubs(:user).returns(@user)
    @grading_task.stubs(:id).returns(123)
  end

  test "initializes with grading task" do
    # Setup
    service = GradingTaskAccessTokenService.new(@grading_task)

    # Verify
    assert_equal @grading_task, service.instance_variable_get(:@grading_task)
  end

  test "successfully fetches access token" do
    # Setup
    token_service = mock("TokenService")
    TokenService.expects(:new).with(@user).returns(token_service)
    token_service.expects(:access_token).returns("valid_access_token")

    service = GradingTaskAccessTokenService.new(@grading_task)

    # Exercise
    token = service.fetch_token

    # Verify
    assert_equal "valid_access_token", token
  end

  test "raises error when token retrieval fails" do
    # Setup
    token_service = mock("TokenService")
    TokenService.expects(:new).with(@user).returns(token_service)
    token_service.expects(:access_token).raises(TokenService::TokenError.new("Token expired"))

    service = GradingTaskAccessTokenService.new(@grading_task)

    # Exercise & Verify
    assert_raises(StandardError) do
      service.fetch_token
    end
  end

  test "raises error when grading task has no user" do
    # Setup
    @grading_task.stubs(:user).returns(nil)

    service = GradingTaskAccessTokenService.new(@grading_task)

    # Exercise & Verify
    assert_raises(StandardError) do
      service.fetch_token
    end
  end
end
