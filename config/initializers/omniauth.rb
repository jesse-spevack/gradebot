Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2,
           ENV["GOOGLE_CLIENT_ID"],
           ENV["GOOGLE_CLIENT_SECRET"],
           {
             scope: %w[
               email
               profile
               https://www.googleapis.com/auth/drive.file
               https://www.googleapis.com/auth/spreadsheets
               https://www.googleapis.com/auth/documents
             ].join(" "),
             access_type: "offline",
             prompt: "consent"
           }
end

# Test mode configuration
if Rails.env.test?
  OmniAuth.config.test_mode = true
end
