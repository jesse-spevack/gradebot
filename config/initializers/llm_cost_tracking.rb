# Initializer for LLM cost tracking configuration
unless Rails.env.test? # Skip in test environment to avoid loading conflicts
  Rails.application.config.after_initialize do
    # Load the required modules
    require "llm/cost_tracking"
    require "llm/cost_tracking_decorator"
    require "llm/cost_tracking_initializer"

    # Enable or disable auto-tracking based on configuration
    auto_track = Rails.configuration.x.llm.try(:auto_track_costs) || true

    # Get the client factory if it exists and has the needed method
    client_factory = nil
    if defined?(LLM::ClientFactory)
      if LLM::ClientFactory.respond_to?(:create_client)
        client_factory = LLM::ClientFactory
      else
        Rails.logger.warn("LLM::ClientFactory exists but doesn't have create_client method")
      end
    end

    # Initialize the cost tracking system
    LLM::CostTrackingInitializer.initialize(
      auto_track: auto_track,
      client_factory: client_factory
    )

    # Log initialization status
    Rails.logger.info("LLM cost tracking initialized (auto-tracking: #{auto_track})")
  end
end
