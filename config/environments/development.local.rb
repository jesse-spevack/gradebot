require "json"

# Load secrets from Kamal
begin
  secrets_output = `kamal secrets print`
  secrets_json_str = secrets_output.lines.find { |line| line.start_with?("SECRETS=") }&.split("=", 2)&.last

  if secrets_json_str
    secrets = JSON.parse(secrets_json_str.gsub("\\", ""))

    # Map Kamal secrets to environment variables
    secret_mappings = {
      "GOOGLE_CLIENT_ID" => "keys/gradebot/add more/GOOGLE_CLIENT_ID",
      "GOOGLE_CLIENT_SECRET" => "keys/gradebot/add more/GOOGLE_CLIENT_SECRET",
      "GOOGLE_API_KEY" => "keys/gradebot/add more/GOOGLE_API_KEY",
      "ANTHROPIC_API_KEY" => "keys/gradebot/add more/ANTHROPIC_API_KEY",
      "GOOGLE_AI_KEY" => "keys/gradebot/add more/GOOGLE_AI_KEY"
    }

    # Set each environment variable
    secret_mappings.each do |env_var, secret_path|
      ENV[env_var] = secrets[secret_path] if secrets[secret_path]
    end
  else
    Rails.logger.warn "No secrets found in Kamal output"
  end
rescue => e
  Rails.logger.error "Failed to load Kamal secrets: #{e.message}"
end
