# Test script to verify cost tracking functionality
puts "=== LLM Cost Tracking Test ==="

# Clear any existing cost logs to ensure clean test
puts "Clearing existing cost logs..."
LLMCostLog.delete_all
puts "Current cost log count: #{LLMCostLog.count}"

# Create a client using the factory
puts "\nCreating LLM client..."
config = { model: "claude-3-sonnet" }
llm_client = LLMClient.new(config)

# Set up a context for tracking
context = {
  request_type: "test_cost_tracking",
  metadata: {
    test_id: "manual-test-#{Time.now.to_i}",
    source: "troubleshooting"
  }
}

# Generate a response
puts "\nGenerating response from LLM..."
response = llm_client.generate("This is a test prompt to verify cost tracking is working correctly.", context: context)

# Check if response includes expected metadata
puts "\nResponse received:"
puts "- Content: #{response[:content].to_s.truncate(50)}"
if response[:metadata]
  puts "- Metadata present: yes"
  puts "- Tokens: #{response[:metadata][:tokens].inspect}" if response[:metadata][:tokens]
  puts "- Cost: #{response[:metadata][:cost]}" if response[:metadata][:cost]
else
  puts "- Metadata present: no"
end

# Check for cost logs
puts "\nChecking for cost logs..."
sleep(1) # Brief pause to ensure async operations complete
logs = LLMCostLog.order(created_at: :desc).limit(5)

if logs.any?
  puts "Found #{logs.count} recent cost logs:"
  logs.each do |log|
    puts "- ID: #{log.id}"
    puts "  Model: #{log.llm_model_name}"
    puts "  Request Type: #{log.request_type}"
    puts "  Tokens: #{log.total_tokens} (prompt: #{log.prompt_tokens}, completion: #{log.completion_tokens})"
    puts "  Cost: #{log.cost}"
    puts "  Created: #{log.created_at}"
    puts "  Metadata: #{log.metadata.inspect}" if log.metadata
    puts ""
  end
else
  puts "No cost logs found. Cost tracking may still not be working correctly."
end

puts "=== Test Complete ==="
