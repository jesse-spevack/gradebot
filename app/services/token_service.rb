# frozen_string_literal: true

# Service for managing OAuth tokens
#
# This service handles token retrieval, validation, and refreshing
# for background jobs that need to access Google APIs on behalf of users.
class TokenService
  class TokenError < StandardError; end
  class RefreshError < TokenError; end
  class NoValidTokenError < TokenError; end

  # Google OAuth token endpoint
  TOKEN_URL = "https://oauth2.googleapis.com/token".freeze

  # Initialize with a user
  #
  # @param user [User] the user to manage tokens for
  def initialize(user)
    @user = user
  end

  # Get a valid access token for the user
  #
  # Retrieves the most recent token, refreshes it if needed,
  # and returns the access token string.
  #
  # @return [String] a valid access token
  # @raise [NoValidTokenError] if no valid token can be found or refreshed
  def access_token
    Rails.logger.info("===== TOKEN SERVICE DEBUG =====")
    Rails.logger.info("Fetching access token for user #{@user.id}")
    
    token = get_valid_token
    Rails.logger.info("Retrieved token ID: #{token.id}, created: #{token.created_at}, expires: #{token.expires_at}")
    Rails.logger.info("Token scopes: #{token.scopes}")
    Rails.logger.info("Token expired? #{token.expired?}, will expire soon? #{token.will_expire_soon?}")
    
    access_token_value = token.access_token
    Rails.logger.info("Access token first/last 10 chars: #{access_token_value[0..9]}...#{access_token_value[-10..-1] rescue 'N/A'}")
    Rails.logger.info("===== END TOKEN SERVICE DEBUG =====")
    
    access_token_value
  end

  # Get a valid user token
  #
  # Retrieves the most recent token and refreshes it if it's expired or will expire soon.
  #
  # @return [UserToken] a valid user token
  # @raise [NoValidTokenError] if no valid token can be found or refreshed
  def get_valid_token
    token = UserToken.most_recent_for(@user)
    Rails.logger.info("Most recent token for user #{@user.id}: #{token&.id || 'None found'}")
    
    raise NoValidTokenError, "No token found for user #{@user.id}" unless token

    if token.expired? || token.will_expire_soon?
      Rails.logger.info("Token needs refresh: expired=#{token.expired?}, expires_soon=#{token.will_expire_soon?}")
      refresh_token(token)
    else
      Rails.logger.info("Token is valid, using as-is")
    end

    token
  end

  # Refresh a token using Google OAuth API
  #
  # @param token [UserToken] the token to refresh
  # @return [UserToken] the refreshed token
  # @raise [RefreshError] if the token cannot be refreshed
  def refresh_token(token)
    begin
      Rails.logger.info("Refreshing token for user #{@user.id}")

      # Check if we're in test environment - use simplified approach if so
      if Rails.env.test? && !ENV["FORCE_REAL_OAUTH_REFRESH"]
        simulate_token_refresh(token)
      else
        perform_oauth_token_refresh(token)
      end

      token
    rescue StandardError => e
      Rails.logger.error("Failed to refresh token for user #{@user.id}: #{e.message}")
      raise RefreshError, "Failed to refresh token: #{e.message}"
    end
  end

  # Create a Google API client with the user's credentials
  #
  # @return [Google::Apis::DriveV3::DriveService] a configured Google Drive client
  # @raise [NoValidTokenError] if no valid token can be found or refreshed
  def create_google_drive_client
    service = Google::Apis::DriveV3::DriveService.new
    service.authorization = access_token
    service
  end

  private

  # Simulate a token refresh for testing
  #
  # @param token [UserToken] the token to refresh
  # @return [UserToken] the refreshed token
  def simulate_token_refresh(token)
    token.update!(
      access_token: "refreshed_access_token_#{SecureRandom.hex(8)}",
      expires_at: 1.hour.from_now
    )
  end

  # Perform an actual OAuth token refresh using Google's API
  #
  # @param token [UserToken] the token to refresh
  # @return [UserToken] the refreshed token
  # @raise [RefreshError] if the token cannot be refreshed
  def perform_oauth_token_refresh(token)
    # Set up the HTTP request to Google's OAuth token endpoint
    uri = URI.parse(TOKEN_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    # Set up the request with required parameters
    request = Net::HTTP::Post.new(uri.path)
    request["Content-Type"] = "application/x-www-form-urlencoded"

    # Build the request body with the OAuth parameters
    request.set_form_data({
      "grant_type" => "refresh_token",
      "refresh_token" => token.refresh_token,
      "client_id" => ENV["GOOGLE_CLIENT_ID"],
      "client_secret" => ENV["GOOGLE_CLIENT_SECRET"]
    })

    # Send the request to Google's OAuth server
    response = http.request(request)

    # Handle the response
    if response.code.to_i == 200
      # Parse the response body to get the new token details
      data = JSON.parse(response.body)

      # Update the token with the new values
      # Note: Google doesn't always return a new refresh token, so we keep the old one
      update_params = {
        access_token: data["access_token"],
        expires_at: Time.current + data["expires_in"].to_i.seconds
      }

      # Update the refresh token if one was returned
      update_params[:refresh_token] = data["refresh_token"] if data["refresh_token"].present?

      # Save the updated token
      token.update!(update_params)
    else
      # Log the error details for debugging
      error_msg = "Google OAuth API error (#{response.code})"
      error_body = JSON.parse(response.body) rescue { error: response.body }
      error_details = error_body["error_description"] || error_body["error"] || "Unknown error"

      Rails.logger.error("#{error_msg}: #{error_details}")
      raise RefreshError, "#{error_msg}: #{error_details}"
    end
  end
end
