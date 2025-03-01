# frozen_string_literal: true

require "test_helper"

class LLM::ConfigurationTest < ActiveSupport::TestCase
  setup do
    @feature_flag_service = FeatureFlagService.new
    @user = users(:teacher)
    # Clear the cache before each test
    Rails.cache.clear
  end

  test ".enabled? returns true when feature flag is enabled" do
    # Create the flag if it doesn't exist
    flag = FeatureFlag.find_or_initialize_by(key: "llm_enabled")
    flag.update(name: "LLM Enabled", enabled: false) if flag.new_record?

    # Enable the flag using the service
    @feature_flag_service.enable("llm_enabled", @user)

    assert LLM::Configuration.enabled?
  end

  test ".enabled? returns false when feature flag is disabled" do
    # Create the flag if it doesn't exist
    flag = FeatureFlag.find_or_initialize_by(key: "llm_enabled")
    flag.update(name: "LLM Enabled", enabled: true) if flag.new_record?

    # Disable the flag using the service
    @feature_flag_service.disable("llm_enabled", @user)

    refute LLM::Configuration.enabled?
  end

  test ".model_for returns the configuration for grade_assignment task" do
    result = LLM::Configuration.model_for(:grade_assignment)

    assert_equal :anthropic, result[:provider]
    assert_equal "claude-3-5-sonnet", result[:model]
    assert_equal 0.7, result[:temperature]
    assert_equal 4000, result[:max_tokens]
  end

  test ".model_for raises error for invalid task type" do
    error = assert_raises(ArgumentError) do
      LLM::Configuration.model_for(:invalid_task)
    end

    assert_match(/Unsupported task type/, error.message)
  end

  test ".default_model returns the default model configuration" do
    result = LLM::Configuration.default_model

    assert_equal :anthropic, result[:provider]
    assert_equal "claude-3-5-sonnet", result[:model]
    assert_equal 0.7, result[:temperature]
  end

  test "configuration defines supported models for all providers" do
    assert_includes LLM::Configuration::MODELS.keys, :anthropic
    assert_includes LLM::Configuration::MODELS.keys, :openai
    assert_includes LLM::Configuration::MODELS.keys, :google

    LLM::Configuration::MODELS.each do |provider, configs|
      assert_includes configs.keys, :default
      assert_includes configs[:default].keys, :provider
      assert_includes configs[:default].keys, :model
      assert_includes configs[:default].keys, :temperature
    end
  end

  test "configuration defines task configurations" do
    assert_includes LLM::Configuration::TASK_CONFIGURATIONS.keys, :grade_assignment

    LLM::Configuration::TASK_CONFIGURATIONS.each do |task, config|
      assert_includes config.keys, :provider
      assert_includes LLM::Configuration::MODELS.keys, config[:provider]
    end
  end
end
