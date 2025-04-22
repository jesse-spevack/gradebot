# frozen_string_literal: true

module AssignmentsHelper
  def options_for_grade_level_select
    Assignment::GRADE_LEVELS.map { |level| [ display_grade(level), level ] }.freeze
  end

  # Returns a displayable grade level
  def display_grade(level)
    if level == "university"
      "University"
    else
      "#{level}th grade"
    end
  end
end
