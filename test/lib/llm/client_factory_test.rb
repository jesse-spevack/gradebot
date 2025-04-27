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

  test ".create returns Anthropic client" do
    client = LLM::ClientFactory.create

    assert_instance_of LLM::Anthropic::Client, client
  end
end
