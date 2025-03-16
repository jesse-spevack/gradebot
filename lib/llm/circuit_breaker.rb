# frozen_string_literal: true

module LLM
  # Implements the circuit breaker pattern for LLM API calls
  #
  # This class provides a way to prevent cascading failures by temporarily
  # stopping operations when the API is consistently failing.
  class CircuitBreaker
    # Keys used in cache
    FAILURE_COUNT_KEY = "llm:circuit_breaker:%s:failure_count".freeze
    LAST_FAILURE_KEY = "llm:circuit_breaker:%s:last_failure".freeze
    CIRCUIT_STATE_KEY = "llm:circuit_breaker:%s:state".freeze

    # States
    CLOSED = "closed".freeze
    OPEN = "open".freeze
    HALF_OPEN = "half_open".freeze

    # Configuration
    FAILURE_THRESHOLD = 3  # Number of failures before opening circuit
    TIMEOUT_SECONDS = 120  # Time to wait before trying again

    # Initialize a new circuit breaker
    #
    # @param service_name [String] The name of the service to monitor
    def initialize(service_name)
      @service_name = service_name
      @cache = Rails.cache  # Use Rails.cache (Solid Cache)

      # Ensure the circuit starts in a known state
      initialize_cache
    end

    # Check if the circuit is closed (allowing requests)
    #
    # @return [Boolean] true if requests are allowed, false otherwise
    def allow_request?
      current_state = get_state

      case current_state
      when CLOSED
        true
      when OPEN
        # Check if timeout has elapsed to transition to half-open
        last_failure = @cache.read(LAST_FAILURE_KEY % @service_name).to_i
        if Time.now.to_i - last_failure > TIMEOUT_SECONDS
          @cache.write(CIRCUIT_STATE_KEY % @service_name, HALF_OPEN)
          Rails.logger.info("Circuit breaker for #{@service_name} transitioning to half-open state")
          true  # Allow one test request
        else
          false # Still open, don't allow requests
        end
      when HALF_OPEN
        true  # Allow test request in half-open state
      else
        # Default to closed if state is unknown
        initialize_cache
        true
      end
    end

    # Record a successful request
    #
    # @return [void]
    def record_success
      current_state = get_state

      if current_state == HALF_OPEN
        # If successful in half-open state, close the circuit
        @cache.write(CIRCUIT_STATE_KEY % @service_name, CLOSED)
        @cache.write(FAILURE_COUNT_KEY % @service_name, 0)
        Rails.logger.info("Circuit breaker for #{@service_name} closed after successful test request")
      elsif current_state == CLOSED
        # Reset failure count on success in closed state
        @cache.write(FAILURE_COUNT_KEY % @service_name, 0)
      end
    end

    # Record a failed request
    #
    # @return [void]
    def record_failure
      current_state = get_state

      case current_state
      when CLOSED
        # Increment failure count
        failure_count = increment_failure_count

        # If threshold reached, open the circuit
        if failure_count >= FAILURE_THRESHOLD
          @cache.write(CIRCUIT_STATE_KEY % @service_name, OPEN)
          @cache.write(LAST_FAILURE_KEY % @service_name, Time.now.to_i)
          Rails.logger.warn("Circuit breaker opened for #{@service_name} after #{failure_count} failures")
        end
      when HALF_OPEN
        # If failed in half-open state, reopen the circuit
        @cache.write(CIRCUIT_STATE_KEY % @service_name, OPEN)
        @cache.write(LAST_FAILURE_KEY % @service_name, Time.now.to_i)
        Rails.logger.warn("Circuit breaker reopened for #{@service_name} after test request failure")
      end
    end

    private

    # Initialize the cache with default values
    #
    # @return [void]
    def initialize_cache
      @cache.write(CIRCUIT_STATE_KEY % @service_name, CLOSED) unless @cache.exist?(CIRCUIT_STATE_KEY % @service_name)
      @cache.write(FAILURE_COUNT_KEY % @service_name, 0) unless @cache.exist?(FAILURE_COUNT_KEY % @service_name)
      @cache.write(LAST_FAILURE_KEY % @service_name, 0) unless @cache.exist?(LAST_FAILURE_KEY % @service_name)
    end

    # Get the current state of the circuit
    #
    # @return [String] The current state (CLOSED, OPEN, or HALF_OPEN)
    def get_state
      state = @cache.read(CIRCUIT_STATE_KEY % @service_name)
      if state.nil?
        initialize_cache
        CLOSED
      else
        state
      end
    end

    # Increment the failure count
    #
    # @return [Integer] The new failure count
    def increment_failure_count
      key = FAILURE_COUNT_KEY % @service_name
      current = @cache.read(key).to_i
      new_value = current + 1
      @cache.write(key, new_value)
      new_value
    end
  end
end
