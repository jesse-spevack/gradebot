# Document Selection Implementation Plan

## Overview

This document outlines the implementation plan for adding a DocumentSelection model to the Gradebot application. This change supports the transition from a folder-based document selection approach to a multiple document selection approach using the Google Drive API's drive.file scope.

## Background

Previously, the application used the Google Drive API with broader scope permissions to access folders of documents. The new approach uses the more restrictive drive.file scope, which only allows access to specific files that the user has explicitly selected.

As a result the existing reliance on a folder id is no longer possible. Instead, we will use the Google Drive API to fetch the documents by their IDs and store each document's metadata in the **database**.

## Data Model Changes

### ✅ New Model: DocumentSelection

```ruby
# DocumentSelection Model
create_table :document_selections do |t|
  t.references :grading_task, null: false, foreign_key: true
  t.string :document_id, null: false  # Google Drive document ID
  t.string :name                      # Document name
  t.string :mime_type                 # Document MIME type
  t.string :status, default: "selected"  # selected, available, unavailable
  t.json :metadata                    # Additional metadata from Google Drive
  t.timestamps
end
```

### ✅ Update StudentSubmission Model

```ruby
# Add document_selection_id to student_submissions table
add_reference :student_submissions, :document_selection, foreign_key: true

# After this change, the StudentSubmission will have both:
# - belongs_to :grading_task (keep existing)
# - belongs_to :document_selection (new)
```

## ✅ Model Relationships

```ruby
# GradingTask Model
class GradingTask < ApplicationRecord
  has_many :document_selections, dependent: :destroy
  has_many :student_submissions, dependent: :destroy
  # ... existing relationships and validations
end

# DocumentSelection Model
class DocumentSelection < ApplicationRecord
  belongs_to :grading_task
  has_one :student_submission, dependent: :nullify
  
  enum status: {
    selected: "selected",      # Initially selected in picker
    available: "available",    # Verified accessible from Google Drive
    unavailable: "unavailable" # Cannot be accessed
  }
  
  validates :document_id, presence: true
end

# StudentSubmission Model
class StudentSubmission < ApplicationRecord
  belongs_to :grading_task
  belongs_to :document_selection, optional: true
  
  # ... existing methods and validations
end
```

## ✅ Controller Changes

### Update GradingTasksController

```ruby
class GradingTasksController < ApplicationController
  # ...existing code

  def create
    @grading_task = Current.session.user.grading_tasks.build(grading_task_params)
    
    if @grading_task.save
      # Process document selections from form data
      # TODO: Add CreateDocumentSelectionService

      # CreateDocumentSelectionService.new(document_ids: params[:document_ids], document_names: params[:document_names], grading_task: @grading_task).call

      # In CreateDocumentSelectionService
      document_ids = params[:document_ids].split('|')
      document_names = params[:document_names].present? ? 
                        params[:document_names].split('|') : 
                        Array.new(document_ids.length, "Unnamed Document")
      
      # Create document selections
      
      document_selection_attributes = document_ids.map.with_index do |doc_id, index|
        document_id: doc_id,
        name: document_names[index] || "Document #{index + 1}",
        status: "selected"
      end

      result = DocumentSelection.insert_all!(document_selection_attributes)
      
      # Create student submissions based on document selections
      # TODO Update CreateStudentSubmissionsCommand to accept document_selections
      CreateStudentSubmissionsCommand.new(grading_task: @grading_task, document_selections: result).call
      redirect_to grading_task_path(@grading_task), notice: "Grading task was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def grading_task_params
    params.require(:grading_task).permit(:assignment_prompt, :grading_rubric, :document_ids, :document_names)
  end

  def document_selection_params
    params.require(:document_selection).permit(:document_id, :name, :status, :metadata)
  end
end
```

## Service Updates

```ruby
# frozen_string_literal: true

# Service for creating student submissions from Google Drive documents
class SubmissionCreatorService
  # @param grading_task [GradingTask] The grading task to associate with submissions
  # @param documents [Array<Hash>] Array of document information hashes
  def initialize(grading_task:, documents:)
    @grading_task = grading_task
    @documents = documents
  end

  # Creates student submissions for documents using bulk insertion
  # @return [Integer] The number of submissions successfully created
  def create_submissions
    return 0 if @documents.empty?

    Rails.logger.info("Creating submissions for #{@documents.length} documents in grading task #{@grading_task.id}")

    # Prepare bulk insertion data
    submission_count = bulk_create_submissions(valid_documents)

    Rails.logger.info("Successfully created #{submission_count} submissions for grading task #{@grading_task.id}")
    submission_count
  end

  private

  # Creates student submissions in bulk
  # @param documents [Array<Hash>] Array of document information hashes
  # @return [Integer] The number of submissions created
  def bulk_create_submissions(documents)
    return 0 if documents.empty?

    # Prepare attributes for bulk insertion
    submission_attributes = documents.map do |document|
      {
        grading_task_id: @grading_task.id,
        original_doc_id: document.document_id,
        status: StudentSubmission.statuses[:pending],
        metadata: { doc_type: document.mime_type },
        created_at: Time.current,
        updated_at: Time.current
      }
    end

    begin
      # Use insert_all! for bulk insertion
      result = StudentSubmission.insert_all!(submission_attributes)
      result.count
    rescue => e
      Rails.logger.error("Failed to bulk create submissions: #{e.message}")

      # Fallback to individual creation if bulk insertion fails
      fallback_create_submissions(documents)
    end
  end

  # Fallback method to create submissions individually if bulk insertion fails
  # @param documents [Array<Hash>] Array of document information hashes
  # @return [Integer] The number of submissions created
  def fallback_create_submissions(documents)
    submission_count = 0

    documents.each do |document|
      begin
        create_submission(document)
        submission_count += 1
      rescue => e
        Rails.logger.error("Failed to create submission for document #{document[:id]}: #{e.message}")
      end
    end

    submission_count
  end

  # Creates a single student submission for a document
  # @param document [Hash] Document information hash
  # @return [StudentSubmission] The created submission
  def create_submission(document)
    StudentSubmission.create!(
      grading_task: @grading_task,
      original_doc_id: document.document_id,
      status: :pending,
      metadata: { doc_type: document.mime_type }
    )
  end
end

```

## Frontend Changes

### Update JavaScript Controller

Modify the folder_picker_controller.js to store document IDs and names differently:

```javascript
// In handleDocumentsSelection method:
handleDocumentsSelection(docs) {
  console.log("Processing multiple document selection");
  
  // Get all document IDs and names
  const docIds = docs.map(doc => doc[google.picker.Document.ID]);
  const docNames = docs.map(doc => doc[google.picker.Document.NAME]);
  
  // Update the form fields - using new fields
  const documentIdsField = document.querySelector('input[name="document_ids"]');
  const documentNamesField = document.querySelector('input[name="document_names"]');
  
  if (documentIdsField && documentNamesField) {
    // Store pipe-separated lists
    documentIdsField.value = docIds.join('|');
    documentNamesField.value = docNames.join('|');
    
    // Create a better display for multiple documents
    this.selectedFolderTarget.innerHTML = `
      <div style="margin-bottom: 8px; font-weight: bold; color: #16a34a;">
        ✅ Selected ${docs.length} documents:
      </div>
    `;
    
    // Display document list
    // ...existing display code...
  }
}
```

### Update Form View

Update the grading task form to include hidden fields for document IDs and names:

```erb
<%# In app/views/grading_tasks/_form.html.erb or new.html.erb %>
<%= form_with model: @grading_task, local: true do |form| %>
  <%# ...existing form fields... %>
  
  <%# Replace the old folder_id/folder_name fields with new fields %>
  <%= form.hidden_field :document_ids %>
  <%= form.hidden_field :document_names %>
  
  <%# ...folder picker component... %>
<% end %>
```

## Migration Plan

1. Create the document_selections table
2. Add document_selection_id to student_submissions
3. Add the DocumentSelection model
4. Update the StudentSubmission model
5. Add controller logic to handle document selections
6. Implement the DocumentFetcherService
7. Update the CreateStudentSubmissionsCommand
8. Update the frontend components

## Testing Approach

1. Unit tests for DocumentSelection model
2. Unit tests for updated StudentSubmission model
3. Integration tests for document selection and fetching
4. System tests for the end-to-end flow

## Notes For Implementation

- The code samples provided are templates and may need adjustment to fit into the existing codebase.
- Existing tests will need to be updated to handle the new relationships.
- A data migration may be needed if you want to maintain existing data.
- The frontend implementation may vary based on the actual HTML structure of your application.
- Error handling should be refined based on your application's conventions.