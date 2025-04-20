require "test_helper"

class Rubric::CriteriaLevelCreationServiceTest < ActiveSupport::TestCase
  def setup
    @valid_response = {
      criteria: [
        {
          title: "Thesis Development",
          description: "Clarity and strength of main argument",
          position: 1,
          levels: [
            {
              title: "Excellent",
              description: "Clear, sophisticated thesis that offers deep insight",
              position: 1
            },
            {
              title: "Proficient",
              description: "Clear thesis with basic insight",
              position: 2
            },
            {
              title: "Beginning",
              description: "Thesis missing or very unclear",
              position: 3
            }
          ]
        }
      ]
    }.to_json

    @rubric = Rubric::CreationService.call(
      user: users(:teacher),
      title: "Essay Rubric",
      total_points: 100,
      status: :processing
    )
  end

  test "successfully parses valid LLM response" do
    service = Rubric::CriteriaLevelCreationService.new(response: @valid_response, rubric: @rubric)
    result = service.parse

    # Verify criterion was created correctly
    criterion = result.first
    assert_equal "Thesis Development", criterion.title
    assert_equal "Clarity and strength of main argument", criterion.description
    assert_equal 1, criterion.position

    # Verify levels were created with correct points
    levels = criterion.levels.sort_by(&:position)
    assert_equal 3, levels.count

    # First level (Excellent) should get 100 points for 3-level scale
    level = levels.first
    assert_equal "Excellent", level.title
    assert_equal "Clear, sophisticated thesis that offers deep insight", level.description
    assert_equal 1, level.position

    # Second level (Proficient) should get 80 points for 3-level scale
    level = levels.second
    assert_equal "Proficient", level.title
    assert_equal "Clear thesis with basic insight", level.description
    assert_equal 2, level.position

    # Third level (Beginning) should get 60 points for 3-level scale
    level = levels.last
    assert_equal "Beginning", level.title
    assert_equal "Thesis missing or very unclear", level.description
    assert_equal 3, level.position
  end

  test "raises error when response is not valid JSON" do
    assert_raises(JSON::ParserError) do
      Rubric::CriteriaLevelCreationService.new(response: "not json", rubric: @rubric).parse
    end
  end

  test "raises error when criteria array is missing" do
    invalid_response = { something: "else" }.to_json

    assert_raises(Rubric::CriteriaLevelCreationService::MalformedLLMResponseError) do
      Rubric::CriteriaLevelCreationService.new(response: invalid_response, rubric: @rubric).parse
    end
  end

  test "raises error when criterion is missing required fields" do
    invalid_response = {
      criteria: [
        {
          title: "Thesis Development",
          # missing description
          position: 1,
          levels: []
        }
      ]
    }.to_json

    assert_raises(Rubric::CriteriaLevelCreationService::MalformedLLMResponseError) do
      Rubric::CriteriaLevelCreationService.new(response: invalid_response, rubric: @rubric).parse
    end
  end

  test "raises error when level is missing required fields" do
    invalid_response = {
      criteria: [
        {
          title: "Thesis Development",
          description: "Clarity and strength of main argument",
          position: 1,
          levels: [
            {
              title: "Excellent",
              # missing description
              position: 1
            }
          ]
        }
      ]
    }.to_json

    assert_raises(Rubric::CriteriaLevelCreationService::MalformedLLMResponseError) do
      Rubric::CriteriaLevelCreationService.new(response: invalid_response, rubric: @rubric).parse
    end
  end
end
