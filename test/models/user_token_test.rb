require "test_helper"

class UserTokenTest < ActiveSupport::TestCase
  # Create a valid token with all required attributes
  test "should be valid with all attributes" do
    user = users(:teacher)
    token = UserToken.new(
      user: user,
      access_token: "valid_access_token",
      refresh_token: "valid_refresh_token",
      expires_at: 1.hour.from_now,
      scopes: "drive.file"
    )
    assert token.valid?
  end

  # Test user association is required
  test "should require a user" do
    token = UserToken.new(
      access_token: "valid_access_token",
      refresh_token: "valid_refresh_token",
      expires_at: 1.hour.from_now,
      scopes: "drive.file"
    )
    assert_not token.valid?
    assert_includes token.errors[:user], "must exist"
  end

  # Test access token is required
  test "should require an access_token" do
    user = users(:teacher)
    token = UserToken.new(
      user: user,
      refresh_token: "valid_refresh_token",
      expires_at: 1.hour.from_now,
      scopes: "drive.file"
    )
    assert_not token.valid?
    assert_includes token.errors[:access_token], "can't be blank"
  end

  # Test refresh token is required
  test "should require a refresh_token" do
    user = users(:teacher)
    token = UserToken.new(
      user: user,
      access_token: "valid_access_token",
      expires_at: 1.hour.from_now,
      scopes: "drive.file"
    )
    assert_not token.valid?
    assert_includes token.errors[:refresh_token], "can't be blank"
  end

  # Test expiration time is required
  test "should require an expiration_time" do
    user = users(:teacher)
    token = UserToken.new(
      user: user,
      access_token: "valid_access_token",
      refresh_token: "valid_refresh_token",
      scopes: "drive.file"
    )
    assert_not token.valid?
    assert_includes token.errors[:expires_at], "can't be blank"
  end

  # Test expired? method returns true for expired tokens
  test "should detect expired tokens" do
    user = users(:teacher)
    token = UserToken.new(
      user: user,
      access_token: "expired_access_token",
      refresh_token: "valid_refresh_token",
      expires_at: 1.hour.ago,
      scopes: "drive.file"
    )
    assert token.expired?
  end

  # Test will_expire_soon? method returns true for tokens that will expire soon
  test "should detect tokens that will expire soon" do
    user = users(:teacher)
    token = UserToken.new(
      user: user,
      access_token: "soon_to_expire_token",
      refresh_token: "valid_refresh_token",
      expires_at: 5.minutes.from_now,
      scopes: "drive.file"
    )
    assert token.will_expire_soon?

    token.expires_at = 30.minutes.from_now
    assert_not token.will_expire_soon?
  end

  # Test finding the most recent token for a user
  test "should find most recent token for a user" do
    user = users(:teacher)
    UserToken.where(user_id: user.id).delete_all

    # Create an older token
    older_token = UserToken.create!(
      user: user,
      access_token: "older_access_token",
      refresh_token: "older_refresh_token",
      expires_at: 1.hour.from_now,
      scopes: "drive.file",
      created_at: 2.days.ago
    )
    older_token.update_column(:created_at, 2.days.ago)

    # Create a newer token
    newer_token = UserToken.create!(
      user: user,
      access_token: "newer_access_token",
      refresh_token: "newer_refresh_token",
      expires_at: 1.hour.from_now,
      scopes: "drive.file",
      created_at: 1.day.ago
    )
    newer_token.update_column(:created_at, 1.day.ago)

    assert_equal newer_token, UserToken.most_recent_for(user)
  end
end
