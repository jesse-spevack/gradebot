class Assignment < ApplicationRecord
  has_prefix_id :as
  # Associations
  belongs_to :user
  has_one :rubric, dependent: :destroy
  has_many :student_works, dependent: :destroy
  has_one :assignment_summary, dependent: :destroy

  # Grade levels for assignment form
  GRADE_LEVELS = [ "5", "6", "7", "8", "9", "10", "11", "12", "university" ].freeze

  # Feedback tone options for assignment form
  FEEDBACK_TONES = [ "encouraging", "neutral/objective", "critical" ].freeze

  # Validations
  validates :title, presence: true
  validates :subject, presence: true
  validates :grade_level, presence: true, inclusion: { in: GRADE_LEVELS }
  validates :feedback_tone, presence: true, inclusion: { in: FEEDBACK_TONES }
  validates :raw_rubric_text, length: { maximum: 5000 }, allow_blank: true
end
