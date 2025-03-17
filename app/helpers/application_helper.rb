module ApplicationHelper
  # Format a number as dollars with 2 decimal places
  def format_dollars(amount)
    number_to_currency(amount, precision: 2)
  end

  # Convert a number to cents (integer)
  def to_cents(amount)
    (amount * 100).round
  end

  # Truncates a document ID to the first 10 characters followed by ellipses
  #
  # @param doc_id [String] The original document ID to truncate
  # @return [String] The truncated document ID
  def turncate_doc_id(doc_id)
    return "" if doc_id.blank?

    if doc_id.length > 10
      "#{doc_id[0...10]}..."
    else
      doc_id
    end
  end
end
