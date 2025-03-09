module ApplicationHelper
  # Format a number as dollars with 2 decimal places
  def format_dollars(amount)
    number_to_currency(amount, precision: 2)
  end

  # Convert a number to cents (integer)
  def to_cents(amount)
    (amount * 100).round
  end
end
