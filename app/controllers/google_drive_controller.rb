class GoogleDriveController < ApplicationController
  before_action :authenticate_user!

  def credentials
    picker_token = GoogleDriveService.generate_picker_token
    oauth_token = Current.user.google_token

    if picker_token && oauth_token
      render json: {
        picker_token: picker_token,
        oauth_token: oauth_token
      }
    else
      render json: { error: "Sign out and then sign back in." }, status: :service_unavailable
    end
  rescue => e
    Rails.logger.error("Google Drive credentials error: #{e.message}")
    render json: { error: "Sign out and then sign back in." }, status: :service_unavailable
  end

  def folder_contents
    folder_id = params[:folder_id]
    drive_service = GoogleDriveService.new(Current.user.google_token)
    file_count = drive_service.count_files_in_folder(folder_id)

    render json: { file_count: file_count }
  rescue => e
    Rails.logger.error("Google Drive folder contents error: #{e.message}")
    render json: { error: e.message }, status: :service_unavailable
  end
end
