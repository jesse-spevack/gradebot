require "ostruct"
require "google/apis/drive_v3"

class GoogleDriveService
  class Error < StandardError; end
  class ConfigurationError < Error; end
  class AuthenticationError < Error; end
  class ApiError < Error; end
  class InvalidTokenError < Error; end

  PICKER_TOKEN_PREFIX = "picker_token"
  PICKER_TOKEN_EXPIRY = 5.minutes

  class << self
    def configuration
      @configuration ||= OpenStruct.new(
        api_key: ENV["GOOGLE_API_KEY"],
        client_id: ENV["GOOGLE_CLIENT_ID"],
        client_secret: ENV["GOOGLE_CLIENT_SECRET"]
      )
    end

    def configure
      yield(configuration) if block_given?
    end

    def generate_picker_token
      validate_configuration!

      # Generate a short-lived token for the picker using client secret
      digest = OpenSSL::HMAC.hexdigest(
        "sha256",
        configuration.client_secret,
        "#{PICKER_TOKEN_PREFIX}_#{Time.current.to_i}"
      )

      Rails.cache.write(
        cache_key(digest),
        true,
        expires_in: PICKER_TOKEN_EXPIRY
      )

      configuration.api_key # Return API key as picker token
    end

    def validate_picker_token(token)
      return false if token.blank?
      Rails.cache.exist?(cache_key(token))
    end

    private

    def cache_key(token)
      "#{PICKER_TOKEN_PREFIX}_#{token}"
    end

    def validate_configuration!
      missing_keys = []
      %i[api_key client_id client_secret].each do |key|
        missing_keys << key if configuration.public_send(key).blank?
      end

      if missing_keys.any?
        raise ConfigurationError, "Missing required Google API configuration: #{missing_keys.join(", ")}"
      end
    end
  end

  def initialize(access_token)
    @access_token = access_token
    validate_access_token!
  end

  private

  def validate_access_token!
    raise AuthenticationError, "Missing access token" if @access_token.blank?
  end
end
