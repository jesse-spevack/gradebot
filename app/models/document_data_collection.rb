# frozen_string_literal: true

# Represents a collection of documents selected for grading
#
# This class manages a collection of DocumentDataItem objects,
# providing validation and easy access to the collection.
class DocumentDataCollection
  include ActiveModel::Model
  include ActiveModel::Validations

  MAX_DOCUMENTS = 35
  attr_reader :items

  validate :validate_items_count
  validate :validate_items

  # Create a new collection from an array of document data
  # @param data [Array<Hash>] Array of document data hashes
  def initialize(data = [])
    @items = []
    return unless data.is_a?(Array)

    @items = data.map { |item| DocumentDataItem.new(item) }
  end

  # Total count of documents
  def count
    @items.count
  end

  # Check if the collection is empty
  def empty?
    @items.empty?
  end

  # Get a document item by index
  def [](index)
    @items[index]
  end

  # Get the first item
  def first
    @items.first
  end

  # Convert all items to an array of hashes for bulk creation
  # @param grading_task_id [Integer] The ID of the grading task
  # @return [Array<Hash>] Array of hashes ready for DocumentSelection.insert_all
  def to_selection_params(grading_task_id)
    @items.map { |item| item.to_selection_params(grading_task_id) }
  end

  # Create a collection from JSON string
  # @param json_string [String] JSON string of document data
  # @return [DocumentDataCollection] New collection
  def self.from_json(json_string)
    return new if json_string.blank?

    begin
      data = JSON.parse(json_string)
      new(data)
    rescue JSON::ParserError
      new
    end
  end

  private

  def validate_items_count
    if @items.count > MAX_DOCUMENTS
      errors.add(:base, "Maximum of #{MAX_DOCUMENTS} documents allowed, but #{@items.count} were provided")
    end

    if @items.empty?
      errors.add(:base, "At least one document must be selected")
    end
  end

  def validate_items
    @items.each_with_index do |item, index|
      next if item.valid?

      item.errors.full_messages.each do |message|
        errors.add(:base, "Document #{index + 1}: #{message}")
      end
    end
  end
end
