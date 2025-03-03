class ParsingError < StandardError
  attr_reader :strategy_errors

  def initialize(message, strategy_errors = [])
    super(message)
    @strategy_errors = strategy_errors
  end

  def detailed_message
    return message if strategy_errors.empty?

    details = strategy_errors.map do |err|
      "- #{err[:strategy]}: #{err[:error]}"
    end.join("\n")

    "#{message}\nDetails:\n#{details}"
  end
end
