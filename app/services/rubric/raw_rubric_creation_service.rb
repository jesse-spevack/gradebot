class Rubric::RawRubricCreationService
  def self.call(raw_text:, rubric:, grading_task:)
    new(raw_text: raw_text, rubric: rubric, grading_task: grading_task).call
  end

  def initialize(raw_text:, rubric:, grading_task:)
    @raw_text = raw_text
    @rubric = rubric
    @grading_task = grading_task
  end

  def call
    RawRubric.create!(
      rubric: @rubric,
      grading_task: @grading_task,
      content: @raw_text
    )
  end
end
