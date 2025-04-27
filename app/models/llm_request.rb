# frozen_string_literal: true

# Represents a structured request to an LLM service
#
# This class encapsulates all parameters needed for an LLM request and
# provides validation to ensure required fields are present and
# properly formatted. It also helps standardize requests across
# different parts of the application.
class LLMRequest
  include ActiveModel::Model
  include ActiveModel::Validations

  attr_accessor :prompt, :llm_model_name, :user, :trackable,
                :request_type, :temperature, :max_tokens,
                :metadata, :request_id, :top_p

  validates :prompt, presence: true
  validates :llm_model_name, presence: true
  validates :request_type, presence: true
  validates :temperature, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }, allow_nil: true
  validates :max_tokens, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :top_p, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }, allow_nil: true

  # Initialize a new LLM request with default values
  #
  # @param attributes [Hash] The attributes to initialize the request with
  def initialize(attributes = {})
    super
    @request_id ||= SecureRandom.uuid
    @llm_model_name ||= "claude-3-5-haiku" # Simple default
    @metadata ||= {}
    @temperature ||= 0.7
    @max_tokens ||= 1000
    @top_p ||= 1
  end

  # Convert to parameters for LLM API
  #
  # @return [Hash] Parameters formatted for the LLM client
  def to_api_parameters
    {
      prompt: prompt,
      llm_model_name: llm_model_name,
      temperature: temperature,
      max_tokens: max_tokens,
      top_p: top_p
    }
  end

  # Build a context hash for tracking
  #
  # @return [Hash] Context for cost tracking and request tracing
  def to_context
    {
      request_id: request_id,
      request_type: request_type,
      llm_model_name: llm_model_name,
      user: user,
      trackable: trackable,
      metadata: metadata
    }
  end

  # Create a hash suitable for LLM::Client#generate
  #
  # @return [Hash] Input for the generate method
  def to_input
    {
      prompt: prompt,
      context: to_context
    }
  end
end
