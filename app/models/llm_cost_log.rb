class LLMCostLog < ApplicationRecord
  has_prefix_id :lcl
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
  scope :for_date_range, ->(start_date, end_date) { where(created_at: start_date..end_date) }
  scope :for_trackable, ->(trackable) { where(trackable: trackable) }

  # Class methods
  def self.total_cost
    sum(:cost)
  end

  # Returns the total cost in cents for exact comparison
  def self.total_cost_in_cents
    (total_cost * 100).round
  end

  # Returns cost breakdown by type in cents for exact comparison
  def self.cost_breakdown_by_type_in_cents
    cost_breakdown_by_type.transform_values { |cost| (cost * 100).round }
  end

  def self.cost_breakdown_by_type
    group(:request_type).sum(:cost)
  end

  # Returns cost breakdown by model in cents for exact comparison
  def self.cost_breakdown_by_model_in_cents
    cost_breakdown_by_model.transform_values { |cost| (cost * 100).round }
  end

  def self.cost_breakdown_by_model
    group(:llm_model_name).sum(:cost)
  end

  # Returns cost breakdown by user in cents for exact comparison
  def self.cost_breakdown_by_user_in_cents
    cost_breakdown_by_user.transform_values { |cost| (cost * 100).round }
  end

  def self.cost_breakdown_by_user
    joins(:user).group("users.email").sum(:cost)
  end

  # Returns daily costs in cents for exact comparison
  def self.daily_costs_in_cents(days = 30)
    daily_costs(days).transform_values { |cost| (cost * 100).round }
  end

  def self.daily_costs(days = 30)
    where("created_at >= ?", days.days.ago)
      .group("DATE(created_at)")
      .sum(:cost)
  end

  # Generate report with option to return cents for exact comparison
  def self.generate_report(start_date: 30.days.ago, end_date: Date.today, group_by: nil, in_cents: false)
    scope = for_date_range(start_date, end_date)

    result = case group_by
    when :request_type
      scope.group(:request_type).sum(:cost)
    when :model
      scope.group(:llm_model_name).sum(:cost)
    when :user
      scope.joins(:user).group("users.email").sum(:cost)
    when :day
      scope.group("DATE(created_at)").sum(:cost)
    else
      { "total" => scope.sum(:cost) }
    end

    # Optionally convert to cents for precise comparison
    in_cents ? result.transform_values { |cost| (cost * 100).round } : result
  end

  # Instance methods

  # Convert cost to integer cents
  def to_cents
    (cost * 100).round
  end

  # Format cost as dollars with 4 decimal places
  def to_dollars
    format("$%.4f", cost)
  end
end
