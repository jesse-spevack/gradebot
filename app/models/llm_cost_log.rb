class LlmCostLog < ApplicationRecord
  # Associations
  belongs_to :user, optional: true
  belongs_to :trackable, polymorphic: true, optional: true

  # Validations
  validates :llm_model_name, presence: true
  validates :cost, numericality: { greater_than_or_equal_to: 0 }

  # Scopes
  scope :for_user, ->(user) { where(user: user) }
  scope :for_request_type, ->(type) { where(request_type: type) }
  scope :for_model, ->(model) { where(llm_model_name: model) }
  scope :for_date_range, ->(start_date, end_date) { where(created_at: start_date.beginning_of_day..end_date.end_of_day) }
  scope :for_trackable, ->(trackable) { where(trackable: trackable) }

  # Class methods
  def self.total_cost
    sum(:cost)
  end

  def self.cost_breakdown_by_type
    group(:request_type).sum(:cost)
  end

  def self.cost_breakdown_by_model
    group(:llm_model_name).sum(:cost)
  end

  def self.cost_breakdown_by_user
    joins(:user).group("users.email").sum(:cost)
  end

  def self.daily_costs(days = 30)
    where("created_at >= ?", days.days.ago)
      .group("DATE(created_at)")
      .sum(:cost)
  end

  # Generate cost reports for a given time period
  # @param start_date [Date] Start date for the report
  # @param end_date [Date] End date for the report
  # @param group_by [Symbol] How to group the report data (:day, :user, :model, :request_type)
  # @return [Hash] The cost report data
  def self.generate_report(start_date:, end_date:, group_by: :day)
    logs = for_date_range(start_date, end_date)

    case group_by
    when :day
      logs.group_by { |log| log.created_at.to_date }
          .transform_values { |logs_for_day| logs_for_day.sum(&:cost) }
    when :user
      logs.group_by { |log| log.user&.id || "anonymous" }
          .transform_values { |logs_for_user| logs_for_user.sum(&:cost) }
    when :model
      logs.group_by(&:llm_model_name)
          .transform_values { |logs_for_model| logs_for_model.sum(&:cost) }
    when :request_type
      logs.group_by(&:request_type)
          .transform_values { |logs_for_type| logs_for_type.sum(&:cost) }
    else
      { total: logs.sum(&:cost) }
    end
  end
end
