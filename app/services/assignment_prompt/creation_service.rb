class AssignmentPrompt::CreationService
  def self.call(grading_task:, title:, content:, grade_level: nil, subject: nil, word_count: nil, due_date: nil)
    new(
      grading_task: grading_task,
      title: title,
      content: content,
      grade_level: grade_level,
      subject: subject,
      word_count: word_count,
      due_date: due_date
    ).call
  end

  def initialize(grading_task:, title:, content:, grade_level: nil, subject: nil, word_count: nil, due_date: nil)
    @grading_task = grading_task
    @title = title
    @content = content
    @grade_level = grade_level
    @subject = subject
    @word_count = word_count
    @due_date = due_date
  end

  def call
    AssignmentPrompt.create!(
      grading_task: @grading_task,
      title: @title,
      subject: @subject,
      grade_level: @grade_level,
      word_count: @word_count,
      content: @content,
      due_date: @due_date
    )
  end
end
