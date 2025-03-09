require "test_helper"

class Admin::LLMPricingConfigsControllerTest < ActionDispatch::IntegrationTest
  setup do
    # Clear existing records to avoid validation errors
    LLMPricingConfig.delete_all

    # Create a test pricing config
    @pricing_config = LLMPricingConfig.create!(
      llm_model_name: "test-model",
      prompt_rate: 1.0,
      completion_rate: 2.0,
      description: "Test model"
    )

    # Create a default pricing config
    @default_config = LLMPricingConfig.create!(
      llm_model_name: "default",
      prompt_rate: 10.0,
      completion_rate: 20.0,
      description: "Default pricing"
    )

    # Mock authentication - this is a bit of a hack for integration tests
    # In a real app, we'd use a proper authentication mechanism for tests
    @admin = users(:admin)
    Current.stubs(:user).returns(@admin)
    @admin.stubs(:admin?).returns(true)
    Admin::BaseController.any_instance.stubs(:require_admin).returns(true)
    ApplicationController.any_instance.stubs(:require_authentication).returns(true)
  end

  test "should get index" do
    get admin_llm_pricing_configs_path
    assert_response :success
    # Don't check for specific content since it might change
  end

  test "should get new" do
    get new_admin_llm_pricing_config_path
    assert_response :success
  end

  test "should create pricing config" do
    assert_difference("LLMPricingConfig.count") do
      post admin_llm_pricing_configs_path, params: {
        llm_pricing_config: {
          llm_model_name: "new-model",
          prompt_rate: 3.0,
          completion_rate: 4.0,
          description: "New test model",
          active: true
        }
      }
    end

    assert_redirected_to admin_llm_pricing_configs_path
    assert_equal "LLM pricing configuration was successfully created.", flash[:notice]
  end

  test "should get edit" do
    get edit_admin_llm_pricing_config_path(@pricing_config)
    assert_response :success
  end

  test "should update pricing config" do
    patch admin_llm_pricing_config_path(@pricing_config), params: {
      llm_pricing_config: {
        prompt_rate: 5.0,
        completion_rate: 6.0,
        description: "Updated test model"
      }
    }

    assert_redirected_to admin_llm_pricing_configs_path
    assert_equal "LLM pricing configuration was successfully updated.", flash[:notice]

    # Verify the update
    @pricing_config.reload
    assert_equal 5.0, @pricing_config.prompt_rate
    assert_equal 6.0, @pricing_config.completion_rate
    assert_equal "Updated test model", @pricing_config.description
  end

  test "should destroy pricing config" do
    assert_difference("LLMPricingConfig.count", -1) do
      delete admin_llm_pricing_config_path(@pricing_config)
    end

    assert_redirected_to admin_llm_pricing_configs_path
    assert_equal "LLM pricing configuration was successfully deleted.", flash[:notice]
  end

  test "should not destroy default pricing config" do
    assert_no_difference("LLMPricingConfig.count") do
      delete admin_llm_pricing_config_path(@default_config)
    end

    assert_redirected_to admin_llm_pricing_configs_path
    assert_equal "Cannot delete the default pricing configuration.", flash[:alert]
  end
end
