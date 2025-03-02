class GoogleDriveController < ApplicationController
  before_action :authenticate_user!

  def credentials
    Rails.logger.info("===== GOOGLE DRIVE CREDENTIALS DEBUG =====")
    Rails.logger.info("User ID: #{Current.user.id}, Email: #{Current.user.email}")
    
    picker_token = GoogleDriveService.generate_picker_token
    Rails.logger.info("Generated picker token")
    
    # Use the TokenService to get the access token
    token_service = TokenService.new(Current.user)
    begin
      oauth_token = token_service.access_token
      
      if picker_token && oauth_token
        Rails.logger.info("Successfully generated credentials")
        Rails.logger.info("===== END GOOGLE DRIVE CREDENTIALS DEBUG =====")
        render json: {
          picker_token: picker_token,
          oauth_token: oauth_token
        }
      else
        Rails.logger.error("Failed to generate credentials: picker_token or oauth_token is nil")
        Rails.logger.info("===== END GOOGLE DRIVE CREDENTIALS DEBUG =====")
        render json: { error: "Sign out and then sign back in." }, status: :service_unavailable
      end
    rescue TokenService::TokenError => e
      Rails.logger.error("Google Drive credentials error (TokenError): #{e.message}")
      Rails.logger.error("#{e.backtrace[0..5].join("\n")}")
      Rails.logger.info("===== END GOOGLE DRIVE CREDENTIALS DEBUG =====")
      render json: { error: "Sign out and then sign back in." }, status: :service_unavailable
    end
  rescue => e
    Rails.logger.error("Google Drive credentials error (General): #{e.message}")
    Rails.logger.error("#{e.backtrace[0..5].join("\n")}")
    Rails.logger.info("===== END GOOGLE DRIVE CREDENTIALS DEBUG =====")
    render json: { error: "Sign out and then sign back in." }, status: :service_unavailable
  end

  def folder_contents
    Rails.logger.info("===== FOLDER CONTENTS DEBUG =====")
    folder_id = params[:folder_id]
    Rails.logger.info("Requested folder ID: #{folder_id}")
    Rails.logger.info("User ID: #{Current.user.id}, Email: #{Current.user.email}")
    
    # Use the TokenService to get the access token
    token_service = TokenService.new(Current.user)
    begin
      access_token = token_service.access_token
      drive_service = GoogleDriveService.new(access_token)
      
      Rails.logger.info("About to request folder contents")
      file_count = drive_service.count_files_in_folder(folder_id)
      Rails.logger.info("Received file count: #{file_count}")
      Rails.logger.info("===== END FOLDER CONTENTS DEBUG =====")

      render json: { file_count: file_count }
    rescue TokenService::TokenError => e
      Rails.logger.error("Google Drive token error: #{e.message}")
      Rails.logger.error("#{e.backtrace[0..5].join("\n")}")
      Rails.logger.info("===== END FOLDER CONTENTS DEBUG =====")
      render json: { error: "Token error. Please sign out and sign back in." }, status: :service_unavailable
    rescue => e
      Rails.logger.error("Google Drive folder contents error: #{e.class.name}: #{e.message}")
      Rails.logger.error("#{e.backtrace[0..5].join("\n")}")
      Rails.logger.info("===== END FOLDER CONTENTS DEBUG =====")
      render json: { error: e.message }, status: :service_unavailable
    end
  end
end
