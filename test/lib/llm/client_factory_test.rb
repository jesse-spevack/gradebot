# frozen_string_literal: true

require "test_helper"

class LLM::ClientFactoryTest < ActiveSupport::TestCase
  include LLMTestHelper

  setup do
    # Stub the Anthropic API key
    stub_anthropic_api_key
  end

  teardown do
    # Unstub the Anthropic API key
    unstub_anthropic_api_key
  end

  test ".create returns OpenAI client for gpt models" do
    client = LLM::ClientFactory.create("gpt-4-turbo")

    assert_instance_of LLM::OpenAI::Client, client
    assert_equal "gpt-4-turbo", client.model_name
  end

  test ".create returns Anthropic client for claude models" do
    client = LLM::ClientFactory.create("claude-3-5-sonnet")

    assert_instance_of LLM::Anthropic::Client, client
    assert_equal "claude-3-5-sonnet", client.model_name
  end

  test ".create returns Google client for gemini models" do
    client = LLM::ClientFactory.create("gemini-pro")

    assert_instance_of LLM::Google::Client, client
    assert_equal "gemini-pro", client.model_name
  end

  test ".create raises UnsupportedModelError for unknown model types" do
    error = assert_raises(LLM::Errors::UnsupportedModelError) do
      LLM::ClientFactory.create("unknown-model")
    end

    assert_match(/Unsupported model: unknown-model/, error.message)
  end

  test "works with model names from Configuration" do
    config = LLM::Configuration.model_for(:grade_assignment)
    client = LLM::ClientFactory.create(config[:model])

    assert_instance_of LLM::Anthropic::Client, client
    assert_equal "claude-3-5-sonnet", client.model_name
  end

  test "handles model names as symbols" do
    client = LLM::ClientFactory.create(:gpt4)

    assert_instance_of LLM::OpenAI::Client, client
    assert_equal :gpt4, client.model_name
  end
end
