# frozen_string_literal: true

# Service for fetching documents from a Google Drive folder
class FolderDocumentFetcherService
  # @param access_token [String] Google Drive access token
  # @param folder_id [String] The ID of the Google Drive folder
  def initialize(access_token, folder_id)
    @access_token = access_token
    @folder_id = folder_id
  end

  # Fetches documents from the specified Google Drive folder
  # @return [Array<Hash>] Array of document information hashes
  # @raise [StandardError] If there's an error accessing the folder
  def fetch
    Rails.logger.info("Fetching documents from folder: #{@folder_id}")

    service = GoogleDriveService.new(@access_token)
    documents = service.list_files_in_folder(@folder_id)

    if documents.empty?
      Rails.logger.info("No documents found in folder: #{@folder_id}")
    else
      Rails.logger.info("Found #{documents.length} documents in folder: #{@folder_id}")
    end

    documents
  rescue GoogleDriveService::Error => e
    Rails.logger.error("Failed to fetch documents from folder #{@folder_id}: #{e.message}")
    raise StandardError, "Failed to fetch documents: #{e.message}"
  end
end
