# Test script to verify client decoration
puts "=== LLM Client Decorator Test ==="

# Create a client using the factory
puts "Creating LLM client..."
config = { model: "claude-3-sonnet" }
llm_client = LLMClient.new(config)

# Get the underlying LLM client
puts "\nExamining client from LLM::ClientFactory.create..."
factory_client = LLM::ClientFactory.create(config[:model])
puts "- Class: #{factory_client.class.name}"
if factory_client.is_a?(LLM::CostTrackingDecorator)
  puts "- Decorator applied: Yes"
  puts "- Underlying client class: #{factory_client.client.class.name}"
  puts "- Model name: #{factory_client.llm_model_name}"
else
  puts "- Decorator applied: No"
end

# Get the client from LLMClient
puts "\nExamining client used by LLMClient..."
# We can use the debug log to check this instead of exposing the client
puts "- Check logs for 'LLM client type:' and 'Cost tracking decorator is applied'"

puts "\n=== Test Complete ==="
