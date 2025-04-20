class Rubric::CriteriaLevelCreationService
  class MalformedLLMResponseError < StandardError; end

  RawCriterion = Struct.new(:title, :description, :position, :levels, keyword_init: true)
  RawLevel = Struct.new(:title, :description, :position, keyword_init: true)

  def self.parse(response:, rubric:)
    self.new(response:, rubric:).parse
  end

  def initialize(response:, rubric:)
    @response = response
    @rubric = rubric
  end

  def parse
    rubric_data = validate_rubric_data!(@response)

    ActiveRecord::Base.transaction do
      # First clean up any existing criteria that might have been created in a previous attempt
      @rubric.criteria.destroy_all if @rubric.criteria.exists?

      points_per_criterion = @rubric.total_points / rubric_data.count

      rubric_data.each do |raw_criterion|
        criterion = Criterion.create!(
          rubric: @rubric,
          title: raw_criterion.title,
          description: raw_criterion.description,
          position: raw_criterion.position,
          points: points_per_criterion
        )

        level_count = raw_criterion.levels.count
        points_by_position = Rubric::LevelPointsCalculatorService.calculate(level_count)

        raw_criterion.levels.each do |raw_level|
          Level.create!(
            criterion: criterion,
            title: raw_level.title,
            description: raw_level.description,
            points: points_by_position[raw_level.position],
            position: raw_level.position,
          )
        end
      end
    end
  end

  def validate_rubric_data!(rubric_data)
    raise MalformedLLMResponseError.new("Rubric data is missing") unless rubric_data.present?
    result = JSON.parse(rubric_data)

    criteria = result["criteria"]
    raise MalformedLLMResponseError.new("LLM did not return a criteria array") unless criteria.is_a?(Array)

    criteria.map do |criterion|
      raise MalformedLLMResponseError.new("LLM did not return a criterion") unless criterion.is_a?(Hash)
      raise MalformedLLMResponseError.new("LLM did not return a criterion title") unless criterion["title"].present?
      raise MalformedLLMResponseError.new("LLM did not return a criterion description") unless criterion["description"].present?
      raise MalformedLLMResponseError.new("LLM did not return a criterion position") unless criterion["position"].present?
      raise MalformedLLMResponseError.new("LLM did not return a criterion levels array") unless criterion["levels"].is_a?(Array)

      levels = criterion["levels"].map do |level|
        raise MalformedLLMResponseError.new("LLM did not return a level") unless level.is_a?(Hash)
        raise MalformedLLMResponseError.new("LLM did not return a level title") unless level["title"].present?
        raise MalformedLLMResponseError.new("LLM did not return a level description") unless level["description"].present?
        raise MalformedLLMResponseError.new("LLM did not return a level position") unless level["position"].present?

        RawLevel.new(
          title: level["title"],
          description: level["description"],
          position: level["position"],
        )
      end

      RawCriterion.new(
        title: criterion["title"],
        description: criterion["description"],
        position: criterion["position"],
        levels: levels
      )
    end
  end
end
