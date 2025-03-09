# Define model pricing data
claude_models = [
  {
    llm_model_name: "claude-3-7-sonnet",
    prompt_rate: 3.0,
    completion_rate: 15.0,
    description: "Most intelligent model with visible step-by-step reasoning. 200K context window. 50% discount with batch processing.",
    active: true
  },
  {
    llm_model_name: "claude-3-5-haiku",
    prompt_rate: 0.8,
    completion_rate: 4.0,
    description: "Fastest, most cost-effective model. 200K context window. 50% discount with batch processing. Supports latency optimization for 60% faster inference speed in Amazon Bedrock.",
    active: true
  },
  {
    llm_model_name: "claude-3-opus",
    prompt_rate: 15.0,
    completion_rate: 75.0,
    description: "Powerful model for complex tasks. 200K context window. 50% discount with batch processing.",
    active: true
  },
  {
    llm_model_name: "claude-3-5-sonnet",
    prompt_rate: 3.0,
    completion_rate: 15.0,
    description: "Legacy model. 200K context window. 50% discount with batch processing.",
    active: true
  },
  {
    llm_model_name: "claude-3-haiku",
    prompt_rate: 0.25,
    completion_rate: 1.25,
    description: "Legacy model. 200K context window. 50% discount with batch processing.",
    active: true
  }
]

# Create or update each model config
claude_models.each do |model_data|
  config = LLMPricingConfig.find_or_initialize_by(llm_model_name: model_data[:llm_model_name])
  config.assign_attributes(model_data)

  if config.save
    puts "✅ Successfully saved pricing config for #{model_data[:llm_model_name]}"
  else
    puts "❌ Failed to save pricing config for #{model_data[:llm_model_name]}: #{config.errors.full_messages.join(", ")}"
  end
end

puts "\nAll current LLM pricing configurations:"
puts "----------------------------------------"
LLMPricingConfig.all.each do |config|
  puts "#{config.llm_model_name}: $#{config.prompt_rate} input, $#{config.completion_rate} output - #{config.active? ? "Active" : "Inactive"}"
end
