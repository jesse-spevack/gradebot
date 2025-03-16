# frozen_string_literal: true

require "test_helper"

class LLM::CircuitBreakerTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::TimeHelpers

  setup do
    # Use in-memory cache for testing
    Rails.cache.clear
    @circuit_breaker = LLM::CircuitBreaker.new("test_service")

    # Ensure the cache is initialized with known values
    Rails.cache.write(LLM::CircuitBreaker::CIRCUIT_STATE_KEY % "test_service", LLM::CircuitBreaker::CLOSED)
    Rails.cache.write(LLM::CircuitBreaker::FAILURE_COUNT_KEY % "test_service", 0)
  end

  teardown do
    # Clean up after each test
    travel_back
    Rails.cache.clear
  end

  test "starts in closed state" do
    assert @circuit_breaker.allow_request?
    assert_equal LLM::CircuitBreaker::CLOSED, Rails.cache.read(LLM::CircuitBreaker::CIRCUIT_STATE_KEY % "test_service")
  end

  test "opens after threshold failures" do
    # Record failures up to threshold
    LLM::CircuitBreaker::FAILURE_THRESHOLD.times do
      @circuit_breaker.record_failure
    end

    # Circuit should be open now
    assert_not @circuit_breaker.allow_request?
    assert_equal LLM::CircuitBreaker::OPEN, Rails.cache.read(LLM::CircuitBreaker::CIRCUIT_STATE_KEY % "test_service")
  end

  test "transitions to half-open after timeout" do
    # Record failures to open circuit
    LLM::CircuitBreaker::FAILURE_THRESHOLD.times do
      @circuit_breaker.record_failure
    end

    # Verify circuit is open
    assert_equal LLM::CircuitBreaker::OPEN, Rails.cache.read(LLM::CircuitBreaker::CIRCUIT_STATE_KEY % "test_service")

    # Travel forward in time past the timeout
    travel(LLM::CircuitBreaker::TIMEOUT_SECONDS + 1.second)

    # Circuit should allow one request (half-open)
    assert @circuit_breaker.allow_request?
    assert_equal LLM::CircuitBreaker::HALF_OPEN, Rails.cache.read(LLM::CircuitBreaker::CIRCUIT_STATE_KEY % "test_service")
  end

  test "closes circuit after successful request in half-open state" do
    # Set circuit to half-open state
    Rails.cache.write(LLM::CircuitBreaker::CIRCUIT_STATE_KEY % "test_service", LLM::CircuitBreaker::HALF_OPEN)

    # Record success
    @circuit_breaker.record_success

    # Circuit should be closed
    assert_equal LLM::CircuitBreaker::CLOSED, Rails.cache.read(LLM::CircuitBreaker::CIRCUIT_STATE_KEY % "test_service")
  end

  test "reopens circuit after failure in half-open state" do
    # Set circuit to half-open state
    Rails.cache.write(LLM::CircuitBreaker::CIRCUIT_STATE_KEY % "test_service", LLM::CircuitBreaker::HALF_OPEN)

    # Record failure
    @circuit_breaker.record_failure

    # Circuit should be open again
    assert_equal LLM::CircuitBreaker::OPEN, Rails.cache.read(LLM::CircuitBreaker::CIRCUIT_STATE_KEY % "test_service")
  end

  test "resets failure count on success in closed state" do
    # Record some failures, but not enough to open circuit
    (LLM::CircuitBreaker::FAILURE_THRESHOLD - 1).times do
      @circuit_breaker.record_failure
    end

    # Verify failure count
    assert_equal LLM::CircuitBreaker::FAILURE_THRESHOLD - 1,
      Rails.cache.read(LLM::CircuitBreaker::FAILURE_COUNT_KEY % "test_service").to_i

    # Record success
    @circuit_breaker.record_success

    # Failure count should be reset to 0
    assert_equal 0, Rails.cache.read(LLM::CircuitBreaker::FAILURE_COUNT_KEY % "test_service").to_i
  end
end
