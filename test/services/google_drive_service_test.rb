require "test_helper"

class GoogleDriveServiceTest < ActiveSupport::TestCase
  setup do
    # Store original ENV values
    @original_env = {
      "GOOGLE_API_KEY" => ENV["GOOGLE_API_KEY"],
      "GOOGLE_CLIENT_ID" => ENV["GOOGLE_CLIENT_ID"],
      "GOOGLE_CLIENT_SECRET" => ENV["GOOGLE_CLIENT_SECRET"]
    }

    # Set test ENV values
    ENV["GOOGLE_API_KEY"] = "test_api_key"
    ENV["GOOGLE_CLIENT_ID"] = "test_client_id"
    ENV["GOOGLE_CLIENT_SECRET"] = "test_client_secret"

    # Reset configuration for each test
    GoogleDriveService.instance_variable_set(:@configuration, nil)
  end

  teardown do
    # Restore original ENV values
    @original_env.each do |key, value|
      ENV[key] = value
    end
  end

  test "configuration holds API settings" do
    config = GoogleDriveService.configuration

    assert_equal "test_api_key", config.api_key
    assert_equal "test_client_id", config.client_id
    assert_equal "test_client_secret", config.client_secret
  end

  test "configuration can be updated" do
    GoogleDriveService.configure do |config|
      config.api_key = "new_api_key"
    end

    assert_equal "new_api_key", GoogleDriveService.configuration.api_key
  end

  test "initialization requires access token" do
    error = assert_raises(GoogleDriveService::AuthenticationError) do
      GoogleDriveService.new(nil)
    end

    assert_equal "Missing access token", error.message
  end

  test "initialization validates required configuration" do
    ENV["GOOGLE_API_KEY"] = nil

    error = assert_raises(GoogleDriveService::ConfigurationError) do
      GoogleDriveService.generate_picker_token
    end

    assert_match /Missing required Google API configuration: api_key/, error.message
  end

  test "initialization succeeds with valid configuration" do
    service = GoogleDriveService.new("valid_token")
    assert_instance_of GoogleDriveService, service
  end

  test "validate_folder_access returns true" do
    service = GoogleDriveService.new("valid_token")
    assert service.validate_folder_access("folder_id")
  end
end
