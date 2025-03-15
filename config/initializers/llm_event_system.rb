# Initializer for LLM event system
Rails.application.config.after_initialize do
  begin
    Rails.logger.info "Starting LLM Event System initialization..."

    # Load the required modules - using Rails autoloading instead of require_relative
    # which can be problematic in production environments
    Rails.logger.info "Checking if required LLM modules are loaded..."

    # Check if classes are available before proceeding
    if defined?(LLM::EventSystem) && defined?(LLM::CostTracking) && defined?(LLM::CostTrackingSubscriber)
      Rails.logger.info "All required LLM modules are available"

      # Initialize the cost tracking subscriber
      subscriber = LLM::CostTrackingSubscriber.new
      Rails.logger.info "LLM Cost Tracking Subscriber initialized: #{subscriber.class.name}"

      # Log initialization status
      Rails.logger.info "LLM Event System initialized with cost tracking subscriber"
    else
      missing_modules = []
      missing_modules << "LLM::EventSystem" unless defined?(LLM::EventSystem)
      missing_modules << "LLM::CostTracking" unless defined?(LLM::CostTracking)
      missing_modules << "LLM::CostTrackingSubscriber" unless defined?(LLM::CostTrackingSubscriber)

      Rails.logger.error "LLM Event System initialization failed: Missing required modules: #{missing_modules.join(', ')}"
    end
  rescue => e
    Rails.logger.error "Failed to initialize LLM Event System: #{e.message}"
    Rails.logger.error "Error backtrace: #{e.backtrace&.first(5)&.join("\n")}"
  end
end
