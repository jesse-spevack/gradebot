require "json"

# Load secrets from Kamal
secrets_output = `kamal secrets print`
secrets_json_str = secrets_output.lines.find { |line| line.start_with?("SECRETS=") }&.split("=", 2)&.last
if secrets_json_str
  begin
    secrets = JSON.parse(secrets_json_str.gsub("\\", ""))
    ENV["GOOGLE_CLIENT_ID"] = secrets["keys/gradebot/add more/GOOGLE_CLIENT_ID"]
    ENV["GOOGLE_CLIENT_SECRET"] = secrets["keys/gradebot/add more/GOOGLE_CLIENT_SECRET"]
  rescue JSON::ParserError => e
    Rails.logger.error "Failed to parse Kamal secrets: #{e.message}"
  end
end
