require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @user = users(:teacher)
    # Clear existing tokens for testing
    UserToken.where(user: @user).delete_all
  end

  test "valid user" do
    assert @user.valid?
  end

  test "requires email" do
    @user.email = nil
    assert_not @user.valid?
    assert_includes @user.errors[:email], "can't be blank"
  end

  test "requires unique email" do
    duplicate_user = @user.dup
    @user.save
    assert_not duplicate_user.valid?
    assert_includes duplicate_user.errors[:email], "has already been taken"
  end

  test "requires valid email format" do
    @user.email = "invalid_email"
    assert_not @user.valid?
    assert_includes @user.errors[:email], "is invalid"
  end

  test "requires google_uid" do
    @user.google_uid = nil
    assert_not @user.valid?
    assert_includes @user.errors[:google_uid], "can't be blank"
  end

  test "requires unique google_uid" do
    duplicate_user = @user.dup
    @user.save
    assert_not duplicate_user.valid?
    assert_includes duplicate_user.errors[:google_uid], "has already been taken"
  end

  test "admin defaults to false" do
    user = User.new
    assert_equal false, user.admin
  end

  test "admin? returns admin attribute value" do
    @user.admin = false
    assert_not @user.admin?

    @user.admin = true
    assert @user.admin?
  end

  test "should have a current_google_token method" do
    # Create a token for the user
    token = UserToken.create!(
      user: @user,
      access_token: "test_access_token",
      refresh_token: "test_refresh_token",
      expires_at: 1.hour.from_now,
      scopes: "drive.file"
    )

    assert_equal token, @user.current_google_token
  end

  test "from_google_auth creates or updates user from auth hash" do
    # Clear any existing tokens
    UserToken.delete_all

    auth_hash = {
      "provider" => "google_oauth2",
      "uid" => "different_uid_not_in_a_fixture_or_db_123456",
      "info" => {
        "email" => "test@example.com",
        "name" => "Test User",
        "image" => "https://example.com/photo.jpg"
      },
      "credentials" => {
        "token" => "mock_token",
        "refresh_token" => "mock_refresh_token",
        "expires_at" => 1.hour.from_now.to_i,
        "scope" => "drive.file"
      }
    }

    user = User.from_google_auth(auth_hash)

    assert_instance_of User, user
    assert user.persisted?
    assert_equal auth_hash["info"]["email"], user.email
    assert_equal auth_hash["uid"], user.google_uid
    assert_equal auth_hash["info"]["name"], user.name
    assert_equal auth_hash["info"]["image"], user.profile_picture_url

    # Check that a token was created
    token = user.user_tokens.last
    assert_not_nil token
    assert_equal auth_hash["credentials"]["token"], token.access_token
    assert_equal auth_hash["credentials"]["refresh_token"], token.refresh_token
    assert_equal Time.at(auth_hash["credentials"]["expires_at"]), token.expires_at
  end

  test "from_google_auth updates existing user" do
    # Clear any existing tokens
    UserToken.delete_all

    existing_user = users(:teacher)
    auth_hash = {
      "provider" => "google_oauth2",
      "uid" => existing_user.google_uid,
      "info" => {
        "email" => existing_user.email,
        "name" => "Updated Name",
        "image" => "https://example.com/new_photo.jpg"
      },
      "credentials" => {
        "token" => "new_token",
        "refresh_token" => "new_refresh_token",
        "expires_at" => 1.hour.from_now.to_i,
        "scope" => "drive.file"
      }
    }

    user = User.from_google_auth(auth_hash)

    assert_equal existing_user.id, user.id
    assert_equal "Updated Name", user.name
    assert_equal "https://example.com/new_photo.jpg", user.profile_picture_url

    # Check that a token was created
    token = user.user_tokens.last
    assert_not_nil token
    assert_equal "new_token", token.access_token
    assert_equal "new_refresh_token", token.refresh_token
  end
end
