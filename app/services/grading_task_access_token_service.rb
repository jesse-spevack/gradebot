# frozen_string_literal: true

# Service for retrieving access tokens for a grading task's user
class GradingTaskAccessTokenService
  # @param grading_task [GradingTask] The grading task to get an access token for
  def initialize(grading_task)
    @grading_task = grading_task
  end

  # Fetches the access token for the grading task's user
  # @return [String] The access token
  # @raise [StandardError] If the token cannot be retrieved
  def fetch_token
    user = @grading_task.user

    unless user
      Rails.logger.error("No user associated with grading task #{@grading_task.id}")
      raise StandardError, "No user associated with grading task"
    end

    Rails.logger.info("Fetching access token for user #{user.id}")

    token_service = TokenService.new(user)
    token_service.access_token
  rescue TokenService::TokenError => e
    Rails.logger.error("Failed to get access token for user #{user.id}: #{e.message}")
    raise StandardError, "Failed to get access token: #{e.message}"
  end
end
