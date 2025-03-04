module LLM
  # Initializer for cost tracking configuration and setup
  module CostTrackingInitializer
    class << self
      # Initialize cost tracking with configuration options
      # @param auto_track [Boolean] Whether to automatically decorate clients with cost tracking
      # @param client_factory [LLM::ClientFactory] The client factory to hook into (optional)
      # @return [void]
      def initialize(auto_track: true, client_factory: nil)
        @auto_track = auto_track

        # Hook into the client factory if provided and auto tracking is enabled
        if auto_track && client_factory
          hook_into_client_factory(client_factory)
        end
      end

      # Decorate an existing LLM client with cost tracking
      # @param client [Object] Any LLM client to wrap with cost tracking
      # @return [LLM::CostTrackingDecorator] The decorated client
      def decorate_client(client)
        LLM::CostTrackingDecorator.new(client)
      end

      # Hook into the client factory to automatically wrap clients with cost tracking
      # @param client_factory [LLM::ClientFactory] The client factory to hook into
      # @return [void]
      def hook_into_client_factory(client_factory)
        # Store the original create_client method
        original_method = client_factory.method(:create_client)

        # Redefine the create_client method to wrap clients with the decorator
        client_factory.define_singleton_method(:create_client) do |provider, config = {}|
          # Call the original method to get the client
          client = original_method.call(provider, config)

          # Wrap the client with the decorator
          LLM::CostTrackingDecorator.new(client)
        end
      end
    end
  end
end
