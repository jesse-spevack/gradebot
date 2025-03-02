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

  def validate_folder_access(folder_id)
    # Future implementation: Validate that the user has access to the folder
    # and that it contains the expected structure for grading
    true
  end

  # List all files in a folder
  #
  # @param folder_id [String] The ID of the Google Drive folder
  # @return [Array<Hash>] Array of document information hashes
  def list_files_in_folder(folder_id)
    Rails.logger.info("Listing files in folder: #{folder_id}")

    service = Google::Apis::DriveV3::DriveService.new
    service.authorization = @access_token

    # Query for all files in the folder (excluding subfolders)
    query = "'#{folder_id}' in parents and trashed = false and mimeType != 'application/vnd.google-apps.folder'"

    begin
      response = service.list_files(
        q: query,
        fields: "files(id,name,mimeType)",
        page_size: 1000,
        order_by: "name"
      )

      # Convert the response to a simple array of hashes
      files = response.files.map do |file|
        {
          id: file.id,
          name: file.name,
          mime_type: file.mime_type
        }
      end

      Rails.logger.info("Found #{files.size} files in folder")
      files
    rescue Google::Apis::AuthorizationError => e
      Rails.logger.error("Google Drive authorization error: #{e.message}")
      raise AuthenticationError, "Invalid or expired access token"
    rescue Google::Apis::ClientError => e
      Rails.logger.error("Google Drive client error: #{e.message}")
      raise ApiError, "Failed to list files in folder: #{e.message}"
    end
  end

  def count_files_in_folder(folder_id)
    Rails.logger.info("===== GOOGLE DRIVE DEBUG =====")
    Rails.logger.info("Starting count_files_in_folder for folder: #{folder_id}")
    Rails.logger.info("Access token first/last 10 chars: #{@access_token[0..9]}...#{@access_token[-10..-1] rescue 'N/A'}")
    Rails.logger.info("Access token length: #{@access_token.length}")

    service = Google::Apis::DriveV3::DriveService.new
    service.authorization = @access_token

    # First verify we can access the folder
    Rails.logger.info("Verifying folder access...")
    begin
      folder = service.get_file(
        folder_id,
        fields: "id,name,mimeType"
      )
      Rails.logger.info("Successfully accessed folder: #{folder.to_h}")
    rescue Google::Apis::ClientError => e
      Rails.logger.error("Failed to access folder: #{e.class} - #{e.message}")
      Rails.logger.error("Error details: #{e.body}")
      Rails.logger.error("Error status: #{e.status_code}")
      raise
    rescue => e
      Rails.logger.error("Failed to access folder: #{e.class} - #{e.message}")
      Rails.logger.error("Backtrace: #{e.backtrace[0..5].join("\n")}")
      raise
    end

    # Now list all files in the folder (excluding subfolders)
    Rails.logger.info("Listing files in folder...")
    query = "'#{folder_id}' in parents and trashed = false"
    Rails.logger.info("Using query: #{query}")

    begin
      response = service.list_files(
        q: query,
        fields: "files(id,name,mimeType)",
        page_size: 1000,
        order_by: "name"
      )
      Rails.logger.info("Files found: #{response.files.size}")
      if response.files.size > 0
        Rails.logger.info("First few files: #{response.files[0..2].map(&:to_h)}")
      end

      file_count = response.files.length
      Rails.logger.info("Total files found: #{file_count}")
      Rails.logger.info("===== END GOOGLE DRIVE DEBUG =====")
      file_count
    rescue Google::Apis::ClientError => e
      Rails.logger.error("Failed to list files: #{e.class} - #{e.message}")
      Rails.logger.error("Error details: #{e.body}")
      Rails.logger.error("Error status: #{e.status_code}")
      Rails.logger.error("===== END GOOGLE DRIVE DEBUG =====")
      raise
    rescue => e
      Rails.logger.error("Failed to list files: #{e.class} - #{e.message}")
      Rails.logger.error("Backtrace: #{e.backtrace[0..5].join("\n")}")
      Rails.logger.error("===== END GOOGLE DRIVE DEBUG =====")
      raise
    end
  rescue Google::Apis::AuthorizationError => e
    Rails.logger.error("Google Drive authorization error: #{e.message}")
    Rails.logger.error("Authorization error backtrace: #{e.backtrace.join("\n")}")
    Rails.logger.error("===== END GOOGLE DRIVE DEBUG =====")
    raise AuthenticationError, "Invalid or expired access token"
  rescue Google::Apis::ClientError => e
    Rails.logger.error("Google Drive client error: #{e.message}")
    Rails.logger.error("Client error backtrace: #{e.backtrace.join("\n")}")
    Rails.logger.error("===== END GOOGLE DRIVE DEBUG =====")
    raise ApiError, "Failed to access folder: #{e.message}"
  end

  private

  def validate_access_token!
    raise AuthenticationError, "Missing access token" if @access_token.blank?
  end
end
