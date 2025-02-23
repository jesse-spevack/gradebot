require "test_helper"

class SessionTest < ActiveSupport::TestCase
  def setup
    @user = users(:teacher)
    @session = Session.new(
      user: @user,
      user_agent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)",
      ip_address: "127.0.0.1"
    )
  end

  test "valid session" do
    assert @session.valid?
  end

  test "belongs to user" do
    assert_respond_to @session, :user
    assert_instance_of User, @session.user
  end

  test "requires user" do
    @session.user = nil
    assert_not @session.valid?
    assert_includes @session.errors[:user], "must exist"
  end

  test "requires user_agent" do
    @session.user_agent = nil
    assert_not @session.valid?
    assert_includes @session.errors[:user_agent], "can't be blank"
  end

  test "requires ip_address" do
    @session.ip_address = nil
    assert_not @session.valid?
    assert_includes @session.errors[:ip_address], "can't be blank"
  end

  test "can have multiple sessions for same user" do
    duplicate_session = @session.dup
    @session.save
    assert duplicate_session.valid?
  end

  test "can have multiple sessions from same IP" do
    duplicate_session = @session.dup
    duplicate_session.user = users(:teacher2)
    @session.save
    assert duplicate_session.valid?
  end

  test "can have multiple sessions with same user agent" do
    duplicate_session = @session.dup
    duplicate_session.user = users(:teacher2)
    duplicate_session.ip_address = "192.168.1.1"
    @session.save
    assert duplicate_session.valid?
  end
end
