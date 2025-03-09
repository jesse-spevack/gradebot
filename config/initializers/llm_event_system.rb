# Initializer for LLM event system
Rails.application.config.after_initialize do
  # Load the required modules
  require_relative "../../app/services/llm/event_system"
  require_relative "../../app/services/llm/cost_tracking"
  require_relative "../../app/services/llm/cost_tracking_subscriber"

  # Initialize the cost tracking subscriber
  LLM::CostTrackingSubscriber.new

  # Log initialization status
  Rails.logger.info "LLM Event System initialized with cost tracking subscriber"
end
