# frozen_string_literal: true

require "test_helper"

class Admin::BaseControllerTest < ActiveSupport::TestCase
  test "has require_admin before_action" do
    before_actions = Admin::BaseController._process_action_callbacks
      .select { |callback| callback.kind == :before }
      .map(&:filter)

    assert_includes before_actions, :require_admin,
      "Admin::BaseController should have a before_action :require_admin"
  end
end
