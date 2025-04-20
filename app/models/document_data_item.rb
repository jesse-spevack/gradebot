# frozen_string_literal: true

# Represents a single document from Google Drive selected for grading
#
# This class encapsulates a document selected by the Google Picker
# and provides validation to ensure the document has the required fields.
class DocumentDataItem
  include ActiveModel::Model
  include ActiveModel::Validations

  attr_accessor :id, :name, :url

  validates :id, presence: true
  validates :name, presence: true
  validates :url, presence: true

  def initialize(attributes = {})
    if attributes.is_a?(Hash)
      super(
        id: attributes["id"] || attributes[:id],
        name: attributes["name"] || attributes[:name],
        url: attributes["url"] || attributes[:url]
      )
    else
      super({})
    end
  end

  # Converts to params for DocumentSelection creation
  def to_selection_params(grading_task_id)
    {
      grading_task_id: grading_task_id,
      document_id: id,
      name: name,
      url: url
    }
  end
end
