require "test_helper"

class Rubric::LevelPointsCalculatorServiceTest < ActiveSupport::TestCase
  setup do
    @service = Rubric::LevelPointsCalculatorService
  end

  test "calculates level points based on number of levels" do
    # Setup
    number_of_levels = 5

    # Exercise
    points_by_position = @service.calculate(number_of_levels)

    # Verify
    expected = {
      1 => 100,
      2 => 90,
      3 => 80,
      4 => 70,
      5 => 60
    }

    assert_equal expected, points_by_position
  end

  test "calculates level points for 4 levels" do
    # Setup
    number_of_levels = 4

    # Exercise
    points_by_position = @service.calculate(number_of_levels)

    # Verify
    expected = {
      1 => 100,
      2 => 90,
      3 => 80,
      4 => 70
    }

    assert_equal expected, points_by_position
  end

  test "calculates level points for 3 levels" do
    # Setup
    number_of_levels = 3

    # Exercise
    points_by_position = @service.calculate(number_of_levels)

    # Verify
    expected = {
      1 => 100,
      2 => 80,
      3 => 60
    }

    assert_equal expected, points_by_position
  end

  test "calculates level points for 2 levels" do
    # Setup
    number_of_levels = 2

    # Exercise
    points_by_position = @service.calculate(number_of_levels)

    # Verify
    expected = {
      1 => 100,
      2 => 60
    }

    assert_equal expected, points_by_position
  end

  test "calculates level points for 10 levels" do
    # Setup
    number_of_levels = 10

    # Exercise
    points_by_position = @service.calculate(number_of_levels)

    # Verify
    expected = {
      1 => 100,
      2 => 95,
      3 => 90,
      4 => 85,
      5 => 80,
      6 => 75,
      7 => 70,
      8 => 65,
      9 => 60,
      10 => 55
    }

    assert_equal expected, points_by_position
  end
end
