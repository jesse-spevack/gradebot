class LLMPricingConfig < ApplicationRecord
  has_prefix_id :lpc
  # Validations
  validates :llm_model_name, presence: true, uniqueness: true
  validates :prompt_rate, :completion_rate, presence: true,
            numericality: { greater_than_or_equal_to: 0 }
  validates :active, inclusion: { in: [ true, false ] }

  # Scopes
  scope :active, -> { where(active: true) }

  # Class methods
  def self.for_model(llm_model_name)
    Rails.cache.fetch("llm_pricing/#{llm_model_name}", expires_in: 1.hour) do
      active.find_by(llm_model_name: llm_model_name) || active.find_by(llm_model_name: "default")
    end
  end

  # Instance methods
  def calculate_cost(prompt_tokens, completion_tokens)
    prompt_cost = (prompt_tokens * prompt_rate) / 1_000_000
    completion_cost = (completion_tokens * completion_rate) / 1_000_000

    {
      prompt_cost: prompt_cost,
      completion_cost: completion_cost,
      total_cost: prompt_cost + completion_cost
    }
  end

  # Return all models ordered by name for the admin interface
  def self.ordered
    order(:llm_model_name)
  end
end
