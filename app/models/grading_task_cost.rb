# frozen_string_literal: true

# Value object representing a grading task and its associated cost
class GradingTaskCost
  attr_reader :grading_task, :cost

  # Initialize a new GradingTaskCost
  # @param grading_task [GradingTask] The grading task
  # @param cost [BigDecimal] The total cost associated with the grading task
  def initialize(grading_task:, cost:)
    @grading_task = grading_task
    @cost = cost
  end
end
