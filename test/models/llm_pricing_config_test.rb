require "test_helper"

class LLMPricingConfigTest < ActiveSupport::TestCase
  setup do
    # Clear existing records to avoid validation errors
    LLMPricingConfig.delete_all
  end

  test "should be valid with valid attributes" do
    config = LLMPricingConfig.new(
      llm_model_name: "test-model",
      prompt_rate: 1.0,
      completion_rate: 2.0,
      description: "Test model",
      active: true
    )

    assert config.valid?
  end

  test "should require model_name" do
    config = LLMPricingConfig.new(
      prompt_rate: 1.0,
      completion_rate: 2.0
    )

    assert_not config.valid?
    assert_includes config.errors[:llm_model_name], "can't be blank"
  end

  test "should require unique model_name" do
    # Create a model with a specific name
    LLMPricingConfig.create!(
      llm_model_name: "test-model",
      prompt_rate: 1.0,
      completion_rate: 2.0
    )

    # Try to create another with the same name
    duplicate = LLMPricingConfig.new(
      llm_model_name: "test-model",
      prompt_rate: 3.0,
      completion_rate: 4.0
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:llm_model_name], "has already been taken"
  end

  test "should require non-negative rates" do
    config = LLMPricingConfig.new(
      llm_model_name: "test-model",
      prompt_rate: -1.0,
      completion_rate: -2.0
    )

    assert_not config.valid?
    assert_includes config.errors[:prompt_rate], "must be greater than or equal to 0"
    assert_includes config.errors[:completion_rate], "must be greater than or equal to 0"
  end

  test ".for_model should return config for specific model" do
    # Create test models
    model1 = LLMPricingConfig.create!(
      llm_model_name: "test-model-1",
      prompt_rate: 1.0,
      completion_rate: 2.0
    )

    model2 = LLMPricingConfig.create!(
      llm_model_name: "test-model-2",
      prompt_rate: 3.0,
      completion_rate: 4.0
    )

    # Test retrieval
    result = LLMPricingConfig.for_model("test-model-1")
    assert_equal model1, result
  end

  test ".for_model should return default when model not found" do
    # Create default model
    default = LLMPricingConfig.create!(
      llm_model_name: "default",
      prompt_rate: 10.0,
      completion_rate: 20.0
    )

    # Test fallback to default
    result = LLMPricingConfig.for_model("non-existent-model")
    assert_equal default, result
  end

  test ".ordered should return models in alphabetical order" do
    # Create models in non-alphabetical order
    LLMPricingConfig.create!(llm_model_name: "c-model", prompt_rate: 1.0, completion_rate: 2.0)
    LLMPricingConfig.create!(llm_model_name: "a-model", prompt_rate: 3.0, completion_rate: 4.0)
    LLMPricingConfig.create!(llm_model_name: "b-model", prompt_rate: 5.0, completion_rate: 6.0)

    # Test ordering
    ordered = LLMPricingConfig.ordered
    assert_equal "a-model", ordered.first.llm_model_name
    assert_equal "b-model", ordered.second.llm_model_name
    assert_equal "c-model", ordered.third.llm_model_name
  end
end
