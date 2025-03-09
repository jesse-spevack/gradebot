# Clear existing pricing configs
LLMPricingConfig.delete_all

# Initial pricing configurations for LLM models
# Values are per million tokens

pricing_configs = [
  {
    llm_model_name: 'gpt-3.5-turbo',
    prompt_rate: 0.0005,
    completion_rate: 0.0015,
    description: 'GPT-3.5 Turbo - OpenAI\'s efficient model',
    active: true
  },
  {
    llm_model_name: 'gpt-4',
    prompt_rate: 0.03,
    completion_rate: 0.06,
    description: 'GPT-4 - OpenAI\'s advanced model',
    active: true
  },
  {
    llm_model_name: 'claude-2',
    prompt_rate: 0.008,
    completion_rate: 0.024,
    description: 'Claude 2 - Anthropic\'s capable model',
    active: true
  },
  {
    llm_model_name: 'claude-instant-1',
    prompt_rate: 0.0016,
    completion_rate: 0.0057,
    description: 'Claude Instant - Anthropic\'s faster model',
    active: true
  },
  {
    llm_model_name: 'default',
    prompt_rate: 0.01,
    completion_rate: 0.03,
    description: 'Default fallback pricing for unknown models',
    active: true
  }
]

pricing_configs.each do |config|
  LLMPricingConfig.find_or_initialize_by(llm_model_name: config[:llm_model_name]).update!(config)
end

puts "#{pricing_configs.size} LLM pricing configurations created or updated"
