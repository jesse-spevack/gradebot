class FeedbackItem < ApplicationRecord
  # Prefix ID
  has_prefix_id :fbk

  # Associations
  belongs_to :feedbackable, polymorphic: true

  # Enum for feedback kind
  enum :kind, { strength: 0, opportunity: 1 }

  # Validations
  validates :feedbackable, presence: true
  validates :title, presence: true
  validates :description, presence: true
  validates :kind, presence: true
end
