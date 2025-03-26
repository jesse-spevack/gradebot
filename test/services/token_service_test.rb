require "test_helper"

class TokenServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:teacher)
    @service = TokenService.new(@user)

    # Remove any existing tokens for clean test state
    UserToken.where(user_id: @user.id).delete_all
  end

  test "should retrieve a valid token" do
    # Create a valid token
    token = UserToken.create!(
      user: @user,
      access_token: "valid_access_token",
      refresh_token: "valid_refresh_token",
      expires_at: 1.hour.from_now,
      scopes: "drive.file"
    )

    # The service should retrieve this token
    result = @service.get_valid_token
    assert_equal token, result
    assert_equal "valid_access_token", @service.access_token
  end

  test "should raise error when no token exists" do
    assert_raises(TokenService::NoValidTokenError) do
      @service.get_valid_token
    end
  end

  test "should refresh an expired token" do
    # Create an expired token
    token = UserToken.create!(
      user: @user,
      access_token: "expired_access_token",
      refresh_token: "valid_refresh_token",
      expires_at: 10.minutes.ago,
      scopes: "drive.file"
    )

    # The service should refresh this token
    SecureRandom.stubs(:hex).returns("12345678")
    result = @service.get_valid_token

    # Verify token was refreshed
    assert_equal token.id, result.id
    assert_equal "refreshed_access_token_12345678", result.access_token
    assert result.expires_at > Time.current
  end

  test "should refresh a token that will expire soon" do
    # Create a token that will expire soon
    token = UserToken.create!(
      user: @user,
      access_token: "soon_to_expire_token",
      refresh_token: "valid_refresh_token",
      expires_at: 2.minutes.from_now,
      scopes: "drive.file"
    )

    # The service should refresh this token
    SecureRandom.stubs(:hex).returns("abcdef12")
    result = @service.get_valid_token

    # Verify token was refreshed
    assert_equal token.id, result.id
    assert_equal "refreshed_access_token_abcdef12", result.access_token
    assert result.expires_at > Time.current + 5.minutes
  end

  test "should create a Google Drive client with valid token" do
    # Create a valid token
    UserToken.create!(
      user: @user,
      access_token: "client_access_token",
      refresh_token: "client_refresh_token",
      expires_at: 1.hour.from_now,
      scopes: "drive.file"
    )

    # The service should create a client with this token
    client = @service.create_google_drive_client

    # Verify client was created with the token
    assert_equal "client_access_token", client.authorization
  end

  test "should create a Google docs client with valid token" do
    # Create a valid token
    UserToken.create!(
      user: @user,
      access_token: "client_access_token",
      refresh_token: "client_refresh_token",
      expires_at: 1.hour.from_now,
      scopes: "drive.file"
    )

    # The service should create a client with this token
    client = @service.create_google_docs_client

    # Verify client was created with the token
    assert_equal "client_access_token", client.authorization
  end


  test "should handle token refresh failure" do
    # Create an expired token
    token = UserToken.create!(
      user: @user,
      access_token: "failure_token",
      refresh_token: "failure_refresh_token",
      expires_at: 10.minutes.ago,
      scopes: "drive.file"
    )

    # Simulate a refresh failure
    token.stubs(:update!).raises(StandardError.new("API connection error"))

    # The service should propagate the refresh error
    assert_raises(TokenService::RefreshError) do
      @service.refresh_token(token)
    end
  end
end
