require "test_helper"

class Rubric::RawRubricCreationServiceTest < ActiveSupport::TestCase
  def setup
    @user = users(:teacher)
    @grading_task = grading_tasks(:one)
    @rubric = rubrics(:essay_rubric)
    @valid_text = "Content - 30 points\nOrganization - 20 points\nGrammar - 20 points\nStyle - 30 points"
  end

  test "creates raw rubric with valid input" do
    raw_rubric = Rubric::RawRubricCreationService.call(
      raw_text: @valid_text,
      rubric: @rubric,
      grading_task: @grading_task
    )

    assert raw_rubric.persisted?
    assert_equal @valid_text, raw_rubric.content
    assert_equal @rubric, raw_rubric.rubric
    assert_equal @grading_task, raw_rubric.grading_task
  end

  test "validates text presence" do
    error = assert_raises(ActiveRecord::RecordInvalid) do
      Rubric::RawRubricCreationService.call(
        raw_text: "",
        rubric: @rubric,
        grading_task: @grading_task
      )
    end

    assert_match /Content can't be blank/, error.message
  end

  test "validates text length" do
    error = assert_raises(ActiveRecord::RecordInvalid) do
      Rubric::RawRubricCreationService.call(
        raw_text: "a" * 10_001,
        rubric: @rubric,
        grading_task: @grading_task
      )
    end

    assert_match /Content cannot be longer than 10,000 character/, error.message
  end

  test "validates rubric presence" do
    error = assert_raises(ActiveRecord::RecordInvalid) do
      Rubric::RawRubricCreationService.call(
        raw_text: @valid_text,
        rubric: nil,
        grading_task: @grading_task
      )
    end

    assert_match /Rubric must be provided/, error.message
  end

  test "validates rubric must be persisted" do
    error = assert_raises(ActiveRecord::RecordInvalid) do
      Rubric::RawRubricCreationService.call(
        raw_text: @valid_text,
        rubric: Rubric.new,
        grading_task: @grading_task
      )
    end

    assert_match /Rubric must be saved/, error.message
  end
end
