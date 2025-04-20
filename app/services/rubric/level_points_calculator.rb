# frozen_string_literal: true

class Rubric::LevelPointsCalculator
  def self.calculate(number_of_levels)
    return {} if number_of_levels < 1

    points_by_position = {}

    if number_of_levels <= 5
      # For 5 or fewer levels, use fixed percentages
      percentages = {
        1 => 100,
        2 => 90,
        3 => 80,
        4 => 70,
        5 => 60
      }

      (1..number_of_levels).each do |position|
        points_by_position[position] = percentages[position]
      end
    else
      # For more than 5 levels, calculate evenly distributed percentages
      # from 100 down to 55
      step = (45.0 / (number_of_levels - 1)).round

      (1..number_of_levels).each do |position|
        points = 100 - ((position - 1) * step)
        points_by_position[position] = points
      end
    end

    points_by_position
  end
end
