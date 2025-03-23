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
      client_id = ENV["GOOGLE_CLIENT_ID"]

      if picker_token && oauth_token
        Rails.logger.info("Successfully generated credentials")
        Rails.logger.info("===== END GOOGLE DRIVE CREDENTIALS DEBUG =====")
        render json: {
          picker_token: picker_token,
          oauth_token: oauth_token,
          app_id: client_id.split(".").first
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

  def google_drive_auth_test
    unless Current.user&.admin?
      flash[:alert] = "You do not have permission to access that page."
      redirect_to root_path
    end

    if request.post?
      # Extract document IDs from params
      @document_data = JSON.parse(params[:document_data] || "[]")

      if @document_data.empty?
        flash[:alert] = "No documents were selected"
        redirect_to google_drive_auth_test_google_drive_index_path
        return
      end

      Rails.logger.warn("Google Drive Auth Test - Selected documents: #{@document_data}")

      # Process each selected document
      @document_data.each do |doc|
        doc_id = doc["id"]
        doc_name = doc["name"]

        Rails.logger.warn("Google Drive Auth Test - Processing document: ID=#{doc_id}, Name=#{doc_name}")

        begin
          # Get Google Drive client for current user
          google_drive_client = GetGoogleDriveClientForStudentSubmissionCommand.call(
            student_submission: OpenStruct.new(grading_task: OpenStruct.new(user: Current.user))
          ).result

          # Fetch document content
          document_content = DocumentContentFetcherService.new(
            document_id: doc_id,
            google_drive_client: google_drive_client
          ).fetch

          # Log the document content
          Rails.logger.warn("DOCUMENT CONTENT**************************************************************************")
          Rails.logger.warn("Google Drive Auth Test - Document content for #{doc_name} (#{doc_id}): #{document_content}")
          Rails.logger.warn("DOCUMENT CONTENT**************************************************************************")
        rescue => e
          Rails.logger.error("Google Drive Auth Test - Error processing document #{doc_id}: #{e.message}")
          Rails.logger.error(e.backtrace.join("\n"))
        end
      end

      flash[:notice] = "Google Drive authentication test completed successfully"
      redirect_to google_drive_auth_test_google_drive_index_path
    end
  end
end
