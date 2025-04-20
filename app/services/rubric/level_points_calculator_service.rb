# frozen_string_literal: true

class Rubric::LevelPointsCalculatorService
  LEVEL_POINTS = {
    2 => { 1 => 100, 2 => 60 },
    3 => { 1 => 100, 2 => 80, 3 => 60 },
    4 => { 1 => 100, 2 => 90, 3 => 80, 4 => 70 },
    5 => { 1 => 100, 2 => 90, 3 => 80, 4 => 70, 5 => 60 }
  }.freeze

  def self.calculate(number_of_levels)
    return {} if number_of_levels < 1
    return LEVEL_POINTS[number_of_levels] if LEVEL_POINTS.key?(number_of_levels)

    # For more than 5 levels, distribute evenly from 100 to 55
    points_by_position = {}
    step = 5 # Fixed step of 5 points between levels

    (1..number_of_levels).each do |position|
      points = 100 - ((position - 1) * step)
      points_by_position[position] = points
    end

    points_by_position
  end
end
