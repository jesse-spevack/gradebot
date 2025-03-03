# frozen_string_literal: true

require "test_helper"

class LLMClientTest < ActiveSupport::TestCase
  setup do
    @config = { model: "test-model" }
    @client = LLMClient.new(@config)
  end

  test "generates response from LLM" do
    mock_response = { content: "test response" }
    LLM::ClientFactory.expects(:create).with(@config[:model]).returns(mock_client)
    mock_client.expects(:generate).with({ prompt: "test prompt" }).returns(mock_response)

    response = @client.generate("test prompt")
    assert_equal mock_response, response
  end

  private

  def mock_client
    @mock_client ||= mock("LLMClient")
  end
end
