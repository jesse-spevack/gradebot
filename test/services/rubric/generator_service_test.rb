require "test_helper"

class Rubric::GeneratorServiceTest < ActiveSupport::TestCase
  def setup
    @grading_task = grading_tasks(:one)
    @assignment_prompt = assignment_prompts(:essay_analysis)
    @rubric = rubrics(:empty_rubric)
    @mock_llm_client = mock
    LLM::Client.stubs(:new).returns(@mock_llm_client)
  end

  test "generates rubric with criteria and levels from valid LLM response" do
    # Mock the JSON response we expect from the LLM
    valid_json_response = {
      content: {
        criteria: [
          {
            title: "Thesis Development",
            description: "Clarity and strength of main argument",
            points: 30,
            position: 1,
            levels: [
              {
                title: "Excellent",
                description: "Clear, sophisticated thesis that offers deep insight",
                points: 30,
                position: 1
              },
              {
                title: "Advanced Proficient",
                description: "Clear, well-developed thesis with good insight",
                points: 27,
                position: 2
              },
              {
                title: "Proficient",
                description: "Clear thesis with basic insight",
                points: 24,
                position: 3
              },
              {
                title: "Developing",
                description: "Thesis present but unclear or underdeveloped",
                points: 21,
                position: 4
              },
              {
                title: "Beginning",
                description: "Thesis missing or very unclear",
                points: 18,
                position: 5
              }
            ]
          }
        ]
      }.to_json
    }

    # Mock the prompt builder and LLM client responses
    @mock_llm_client.stubs(:generate).with(kind_of(LLMRequest)).returns(valid_json_response)

    rubric = Rubric::GeneratorService.generate(
      assignment_prompt: @assignment_prompt,
      grading_task: @grading_task,
      rubric: @rubric,
    )

    assert rubric.persisted?
    assert_equal 1, rubric.criteria.count

    criterion = rubric.criteria.first
    assert_equal "Thesis Development", criterion.title
    assert_equal "Clarity and strength of main argument", criterion.description
    assert_equal 100, criterion.points
    assert_equal 1, criterion.position

    assert_equal 5, criterion.levels.count

    level = criterion.levels.first
    assert_equal "Excellent", level.title
    assert_equal "Clear, sophisticated thesis that offers deep insight", level.description
    assert_equal 100, level.points
    assert_equal 1, level.position
  end

  test "logs error when LLM returns malformed JSON" do
    invalid_json = {
      content: "not json"
    }

    @mock_llm_client.stubs(:generate).with(kind_of(LLMRequest)).returns(invalid_json)

    error_log = StringIO.new
    Rails.logger = Logger.new(error_log)


    assert_raises(JSON::ParserError) do
      Rubric::GeneratorService.generate(
        assignment_prompt: @assignment_prompt,
        grading_task: @grading_task,
        rubric: @rubric,
      )
    end

    assert_match /Error parsing LLM response/, error_log.string
  end

  test "uses raw rubric prompt when raw rubric is present" do
    Rubric::RawRubricCreationService.call(
      raw_text: "Teacher input",
      rubric: @rubric,
      grading_task: @grading_task
    )

    invalid_json = {
      content: "not json"
    }

    @mock_llm_client.stubs(:generate).with(kind_of(LLMRequest)).returns(invalid_json)

    service = Rubric::GeneratorService.new(
      assignment_prompt: @assignment_prompt,
      grading_task: @grading_task,
      rubric: @rubric,
    )

    assert_raises(JSON::ParserError) do
      service.generate
    end
  end
end
