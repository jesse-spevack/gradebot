class AssignmentPrompt < ApplicationRecord
  belongs_to :grading_task

  validates :title, presence: true
  validates :content, presence: true
  validates :grade_level, presence: true
  validates :subject, presence: true
  validates :word_count, numericality: { greater_than: 0, allow_nil: true }

  # Grade levels for assignments with display name and value
  GRADE_LEVELS = {
    "5" => "5th Grade",
    "6" => "6th Grade",
    "7" => "7th Grade",
    "8" => "8th Grade",
    "9" => "9th Grade",
    "10" => "10th Grade",
    "11" => "11th Grade",
    "12" => "12th Grade",
    "undergraduate" => "Undergraduate"
  }.freeze

  # Get grade level options formatted for select dropdown
  def self.grade_level_options
    [ [ "Select a grade level", "" ] ] +
    GRADE_LEVELS.map { |value, name| [ name, value ] }
  end

  def formatted_word_count
    return "Not specified" unless word_count.present?

    "#{word_count} words"
  end

  # Returns the human-readable display name for the grade level
  def grade_level_display
    GRADE_LEVELS[grade_level] || grade_level
  end

  def to_llm
    <<-HEREDOC
      # Title
      #{title}
      # Subject
      #{subject}
      # Instructions
      #{content}
      # Grade Level
      #{grade_level}
      # Word Count
      #{word_count}
    HEREDOC
  end
end
