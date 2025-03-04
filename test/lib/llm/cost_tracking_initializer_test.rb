require "test_helper"

class LLM::CostTrackingInitializerTest < ActiveSupport::TestCase
  class DummyClient
    def execute_request(input)
      { content: "test response" }
    end
  end

  class MockClientFactory
    def create_client(provider, config = {})
      DummyClient.new
    end
  end

  def setup
    # Set up test client and factory
    @client = DummyClient.new
    @factory = MockClientFactory.new
  end

  test "decorates a client" do
    # Setup - done in setup method

    # Exercise
    decorated_client = LLM::CostTrackingInitializer.decorate_client(@client)

    # Verify
    assert_instance_of LLM::CostTrackingDecorator, decorated_client
    assert_equal @client, decorated_client.instance_variable_get(:@client)
  end

  test "hooks into client factory" do
    # Setup
    LLM::CostTrackingInitializer.hook_into_client_factory(@factory)

    # Exercise
    client = @factory.create_client(:anthropic)

    # Verify
    assert_instance_of LLM::CostTrackingDecorator, client
  end

  test "initializes with auto tracking" do
    # Setup - done in setup method

    # Exercise
    LLM::CostTrackingInitializer.initialize(auto_track: true, client_factory: @factory)

    # Verify
    client = @factory.create_client(:anthropic)
    assert_instance_of LLM::CostTrackingDecorator, client
  end

  test "initializes without auto tracking" do
    # Setup - use a new factory to avoid contamination from other tests
    factory = MockClientFactory.new

    # Exercise
    LLM::CostTrackingInitializer.initialize(auto_track: false, client_factory: factory)

    # Verify
    client = factory.create_client(:anthropic)
    assert_instance_of DummyClient, client
    assert_not_instance_of LLM::CostTrackingDecorator, client
  end
end
