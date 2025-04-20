class Rubric < ApplicationRecord
  belongs_to :user
  has_many :criteria, dependent: :destroy
  has_one :raw_rubric, dependent: :destroy
  has_many :grading_tasks, dependent: :destroy

  validates :title, presence: true

  enum :status, { pending: 0, processing: 1, complete: 2, failed: 3 }

  # Returns a display-friendly status string
  # @return [String] 'pending', 'processing', 'completed', or 'failed'
  def display_status
    case status
    when "pending"
      "pending"
    when "processing"
      "processing"
    when "complete"
      "completed"
    when "failed"
      "failed"
    else
      # Return the raw status if it doesn't match known values
      status
    end
  end
end
