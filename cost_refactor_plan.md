# LLM Cost Tracking System: Analysis and Refactoring Plan

## Current System Overview

The LLM cost tracking system is designed to monitor, record, and report on the costs associated with Large Language Model API usage throughout the application. Understanding the system's current architecture is essential before proposing improvements.

### Core Components

1. **LLM::CostTracking Module**
   - Located in `lib/llm/cost_tracking.rb`
   - Provides core functionality for tracking LLM API costs
   - Includes methods for context generation, cost calculation, and log recording
   - Contains hardcoded pricing rates for different LLM models

2. **LLM::CostTrackingDecorator**
   - Implements the decorator pattern to wrap LLM clients
   - Intercepts requests and responses to extract token usage and calculate costs
   - Delegates actual LLM API calls to the wrapped client

3. **LLM::CostTrackingInitializer**
   - Located in `lib/llm/cost_tracking_initializer.rb`
   - Provides configuration and initialization functionality
   - Hooks into the client factory to enable automatic cost tracking
   - Uses monkey patching to override factory methods

4. **LLMCostLog Model**
   - Located in `app/models/llm_cost_log.rb`
   - Stores individual cost log entries in the database
   - Provides scopes and methods for querying and aggregating cost data
   - Includes associations with users and trackable objects

5. **Admin Controllers and Views**
   - LLMCostReportsController provides an admin interface for viewing cost data
   - Views display cost breakdowns by user, model, and request type

### Current Workflow

1. **Initialization**:
   - During application startup, the `config/initializers/llm_cost_tracking.rb` initializer runs
   - It configures the cost tracking system and hooks into the client factory
   - If auto-tracking is enabled, all clients created via the factory will be decorated

2. **Request Execution**:
   - Application code requests an LLM client from the factory
   - The factory creates a client and wraps it with the CostTrackingDecorator
   - The application sends a request to the decorated client
   - The decorator captures context information and passes the request to the underlying client
   - After receiving a response, the decorator extracts token usage and calculates costs

3. **Cost Recording**:
   - The decorator calls `LLM::CostTracking.record` with token usage and context
   - The record method calculates the cost based on model-specific pricing
   - It creates an LLMCostLog entry with token counts, cost amount, and metadata
   - Debug logs are written to help with troubleshooting

4. **Reporting**:
   - Admin users access the cost reports controller
   - The controller retrieves and aggregates cost data from LLMCostLog
   - Views present total costs, breakdowns by model and request type, and recent activity

## Issues with Current Implementation

While the current system effectively tracks and records costs, several aspects of its design could be improved:

1. **Scattered Responsibilities**: 
   - Cost tracking logic is spread across multiple modules without clear boundaries
   - Responsibilities like context generation, cost calculation, and logging are intermingled

2. **Monkey Patching**:
   - The system uses monkey patching to override the ClientFactory, which can lead to debugging difficulties
   - Implicit behaviors make the system harder to understand and maintain

3. **Hardcoded Configuration**:
   - Pricing rates are hardcoded in the CostTracking module
   - Updating prices requires code changes and redeployment

4. **Tight Coupling**:
   - Cost tracking is tightly coupled to the client implementation through the decorator pattern
   - Changes to client interfaces may require corresponding changes to the decorator

5. **Limited Error Handling**:
   - Error handling in the cost tracking logic is minimal
   - Failures in cost recording could lead to lost data

6. **Implicit Parameters**:
   - Context and parameters for LLM requests are passed as loosely structured hashes
   - This makes it easy to miss required fields or misuse the API

## Refactoring Suggestions

### 1. Implement a Service Object Pattern

Replace the current module-based approach with service objects that have clear responsibilities and interfaces:

```ruby
# app/services/llm_cost_tracking_service.rb
class LLMCostTrackingService
  def self.track(client_response, context)
    token_data = extract_token_data(client_response)
    cost = calculate_cost(
      client_response[:model_name],
      token_data[:prompt_tokens],
      token_data[:completion_tokens]
    )
    
    create_log_entry(token_data, cost, context)
  end
  
  def self.calculate_cost(model_name, prompt_tokens, completion_tokens)
    pricing = get_pricing(model_name)
    
    prompt_cost = prompt_tokens * pricing[:prompt_rate] / 1_000_000
    completion_cost = completion_tokens * pricing[:completion_rate] / 1_000_000
    
    prompt_cost + completion_cost
  end
  
  def self.get_pricing(model_name)
    # Get pricing from configuration
    LLMPricingConfig.for_model(model_name)
  end
  
  private
  
  def self.extract_token_data(response)
    # Extract token usage based on response format
    # Return standardized token data
  end
  
  def self.create_log_entry(token_data, cost, context)
    LLMCostLog.create!(
      request_type: context[:request_type],
      llm_model_name: context[:model_name],
      prompt_tokens: token_data[:prompt_tokens],
      completion_tokens: token_data[:completion_tokens],
      total_tokens: token_data[:total_tokens],
      cost: cost,
      user: context[:user],
      trackable: context[:trackable],
      metadata: context[:metadata] || {}
    )
  end
end
```

Benefits:
- Clear separation of responsibilities
- Explicit interfaces for each function
- Easier to test and maintain
- Centralized logic in one place

### 2. Use Dependency Injection Instead of Monkey Patching

Replace the current monkey patching approach with a more explicit dependency injection pattern:

```ruby
# lib/llm/client_factory.rb
module LLM
  class ClientFactory
    class << self
      attr_accessor :decorators
      
      def configure
        yield self if block_given?
      end
      
      def create(model_name, options = {})
        client = create_client(model_name, options)
        apply_decorators(client, options)
      end
      
      private
      
      def create_client(model_name, options)
        # Create raw client implementation
      end
      
      def apply_decorators(client, options)
        return client if decorators.nil? || options[:skip_decorators]
        
        decorated_client = client
        decorators.each do |decorator_class|
          decorated_client = decorator_class.new(decorated_client)
        end
        
        decorated_client
      end
    end
  end
end

# Configuration in an initializer
LLM::ClientFactory.configure do |config|
  config.decorators = [LLM::CostTrackingDecorator] if Rails.configuration.llm.track_costs
end
```

Benefits:
- Explicit configuration instead of monkey patching
- Clear documentation of how decorators are applied
- Ability to easily disable decorators for specific requests
- Better testability with clearer boundaries

### 3. Implement a Config Object for Pricing

Extract pricing information to a configurable database model:

```ruby
# db/migrate/YYYYMMDDHHMMSS_create_llm_pricing_configs.rb
class CreateLLMPricingConfigs < ActiveRecord::Migration[7.0]
  def change
    create_table :llm_pricing_configs do |t|
      t.string :model_name, null: false
      t.decimal :prompt_rate, precision: 10, scale: 8, null: false
      t.decimal :completion_rate, precision: 10, scale: 8, null: false
      t.boolean :active, default: true
      t.text :description
      
      t.timestamps
    end
    
    add_index :llm_pricing_configs, :model_name, unique: true
  end
end

# app/models/llm_pricing_config.rb
class LLMPricingConfig < ApplicationRecord
  validates :model_name, presence: true, uniqueness: true
  validates :prompt_rate, :completion_rate, numericality: { greater_than_or_equal_to: 0 }
  
  # Cache for faster lookups
  def self.for_model(model_name)
    Rails.cache.fetch("llm_pricing/#{model_name}", expires_in: 1.hour) do
      find_by(model_name: model_name, active: true) || find_by(model_name: 'default', active: true)
    end
  end
  
  # Seed initial pricing data
  def self.seed_defaults
    default_pricing = [
      { model_name: 'gpt-3.5-turbo', prompt_rate: 0.0005, completion_rate: 0.0015 },
      { model_name: 'gpt-4', prompt_rate: 0.03, completion_rate: 0.06 },
      { model_name: 'claude-2', prompt_rate: 0.008, completion_rate: 0.024 },
      # Add other models as needed
      { model_name: 'default', prompt_rate: 0.01, completion_rate: 0.03 }
    ]
    
    default_pricing.each do |pricing|
      find_or_initialize_by(model_name: pricing[:model_name]).update!(pricing)
    end
  end
end

# Add admin interface for managing pricing
# app/controllers/admin/llm_pricing_configs_controller.rb
```

Benefits:
- Prices can be updated without code changes
- Admin interface can allow non-developers to update pricing
- Default fallback pricing for unknown models
- Caching for better performance

### 4. Use Events/Observers for Tracking

Implement an event-driven approach to decouple cost tracking from client implementation:

```ruby
# lib/event_publisher.rb
class EventPublisher
  class << self
    def publish(event_name, payload = {})
      subscribers_for(event_name).each do |subscriber|
        begin
          subscriber.call(payload)
        rescue => e
          Rails.logger.error("Error in event subscriber: #{e.message}")
          # Optional: report to error tracking service
        end
      end
    end
    
    def subscribe(event_name, &block)
      subscribers_for(event_name) << block
    end
    
    private
    
    def subscribers_for(event_name)
      @subscribers ||= {}
      @subscribers[event_name] ||= []
    end
  end
end

# In LLM clients
def execute_request(input_object)
  response = api_call(input_object)
  
  EventPublisher.publish('llm.request.completed', {
    response: response, 
    context: input_object[:context],
    model_name: model_name
  })
  
  response
end

# In an initializer
EventPublisher.subscribe('llm.request.completed') do |event|
  LLMCostTrackingService.track(event[:response], event[:context])
end
```

Benefits:
- Decouples cost tracking from client implementation
- Allows for multiple subscribers to LLM request events
- Makes testing easier as subscribers can be mocked
- Provides flexibility for future extensions

### 5. Use Request Objects for LLM Calls

Create explicit request objects to validate and document required parameters:

```ruby
# app/models/llm_request.rb
class LLMRequest
  include ActiveModel::Model
  include ActiveModel::Validations
  
  attr_accessor :prompt, :user, :trackable, :request_type, 
                :model_name, :temperature, :max_tokens, :metadata
  
  validates :prompt, presence: true
  validates :model_name, presence: true
  validates :request_type, presence: true
  
  def initialize(attributes = {})
    super
    @model_name ||= Rails.configuration.llm.default_model
    @metadata ||= {}
    @temperature ||= 0.7
    @max_tokens ||= 1000
  end
  
  def to_api_parameters
    {
      model: model_name,
      prompt: prompt,
      temperature: temperature,
      max_tokens: max_tokens
    }
  end
  
  def to_context
    {
      request_id: SecureRandom.uuid,
      request_type: request_type,
      model_name: model_name,
      user: user,
      trackable: trackable,
      metadata: metadata
    }
  end
end

# Usage
request = LLMRequest.new(
  prompt: "Explain quantum computing",
  user: current_user,
  trackable: @assignment,
  request_type: "explanation",
  model_name: "gpt-4"
)

if request.valid?
  client.generate(request.to_api_parameters, context: request.to_context)
else
  # Handle validation errors
end
```

Benefits:
- Validates required parameters before making API calls
- Documents the expected parameters and their defaults
- Provides a consistent interface for different LLM providers
- Makes it easier to add new parameters in the future

### 6. Separate Cost Calculation from Tracking

Separate the cost calculation logic from tracking to follow the Single Responsibility Principle:

```ruby
# app/services/llm_cost_calculator.rb
class LLMCostCalculator
  def self.calculate(model_name, prompt_tokens, completion_tokens)
    pricing = LLMPricingConfig.for_model(model_name)
    
    prompt_cost = prompt_tokens * pricing.prompt_rate / 1_000_000
    completion_cost = completion_tokens * pricing.completion_rate / 1_000_000
    
    {
      prompt_cost: prompt_cost,
      completion_cost: completion_cost,
      total_cost: prompt_cost + completion_cost
    }
  end
  
  def self.estimate_cost(model_name, prompt_tokens, estimated_completion_tokens = nil)
    pricing = LLMPricingConfig.for_model(model_name)
    
    prompt_cost = prompt_tokens * pricing.prompt_rate / 1_000_000
    
    if estimated_completion_tokens
      completion_cost = estimated_completion_tokens * pricing.completion_rate / 1_000_000
      total_cost = prompt_cost + completion_cost
    else
      completion_cost = nil
      total_cost = prompt_cost
    end
    
    {
      prompt_cost: prompt_cost,
      completion_cost: completion_cost,
      total_cost: total_cost
    }
  end
end

# app/services/llm_cost_tracker.rb
class LLMCostTracker
  def self.record(response_data, context)
    # Extract token usage from response
    token_data = extract_token_data(response_data)
    
    # Calculate cost using calculator
    cost_data = LLMCostCalculator.calculate(
      context[:model_name],
      token_data[:prompt_tokens],
      token_data[:completion_tokens]
    )
    
    # Create log record
    LLMCostLog.create!(
      request_type: context[:request_type],
      llm_model_name: context[:model_name],
      prompt_tokens: token_data[:prompt_tokens],
      completion_tokens: token_data[:completion_tokens],
      total_tokens: token_data[:total_tokens],
      cost: cost_data[:total_cost],
      user: context[:user],
      trackable: context[:trackable],
      metadata: context[:metadata] || {}
    )
  end
  
  private
  
  def self.extract_token_data(response_data)
    # Extract token usage based on response format
    # Return standardized token data
  end
end
```

Benefits:
- Clear separation of cost calculation from logging
- Ability to calculate estimated costs before making API calls
- Easier to test each component independently
- Better adherence to the Single Responsibility Principle

### 7. Use Adapter Pattern for Provider-Specific Logic

Extract provider-specific token counting logic into adapters:

```ruby
# app/lib/llm/token_adapters/base_adapter.rb
module LLM
  module TokenAdapters
    class BaseAdapter
      def self.extract_tokens(response)
        raise NotImplementedError, "Subclasses must implement extract_tokens"
      end
    end
  end
end

# app/lib/llm/token_adapters/anthropic_adapter.rb
module LLM
  module TokenAdapters
    class AnthropicAdapter < BaseAdapter
      def self.extract_tokens(response)
        {
          prompt_tokens: response.dig(:usage, :input_tokens) || 0,
          completion_tokens: response.dig(:usage, :output_tokens) || 0,
          total_tokens: (response.dig(:usage, :input_tokens) || 0) + 
                        (response.dig(:usage, :output_tokens) || 0)
        }
      end
    end
  end
end

# app/lib/llm/token_adapters/openai_adapter.rb
module LLM
  module TokenAdapters
    class OpenAIAdapter < BaseAdapter
      def self.extract_tokens(response)
        {
          prompt_tokens: response.dig(:usage, :prompt_tokens) || 0,
          completion_tokens: response.dig(:usage, :completion_tokens) || 0,
          total_tokens: response.dig(:usage, :total_tokens) || 0
        }
      end
    end
  end
end

# app/lib/llm/token_adapters/adapter_factory.rb
module LLM
  module TokenAdapters
    class AdapterFactory
      PROVIDER_MAPPING = {
        /^claude/ => AnthropicAdapter,
        /^gpt/ => OpenAIAdapter,
        # Add other mappings as needed
      }
      
      def self.for_model(model_name)
        PROVIDER_MAPPING.each do |pattern, adapter|
          return adapter if model_name.match?(pattern)
        end
        
        # Default adapter if no match found
        BaseAdapter
      end
    end
  end
end

# Usage in cost tracker
adapter = LLM::TokenAdapters::AdapterFactory.for_model(context[:model_name])
token_data = adapter.extract_tokens(response_data)
```

Benefits:
- Clean separation of provider-specific logic
- Easy to add support for new LLM providers
- Consistent token extraction interface
- Better testability with mock adapters

### 8. Improve Error Handling and Retry Logic

Implement robust error handling with retries for cost recording:

```ruby
# Gemfile
gem 'retriable'

# app/services/llm_cost_recorder.rb
class LLMCostRecorder
  extend Retriable
  
  def self.record(cost_data, context)
    begin
      retriable(tries: 3, 
               on: [ActiveRecord::ConnectionError, PG::ConnectionBad], 
               base_interval: 0.5) do
        LLMCostLog.create!(
          request_type: context[:request_type],
          llm_model_name: context[:model_name],
          prompt_tokens: cost_data[:prompt_tokens],
          completion_tokens: cost_data[:completion_tokens],
          total_tokens: cost_data[:total_tokens],
          cost: cost_data[:total_cost],
          user: context[:user],
          trackable: context[:trackable],
          metadata: context[:metadata] || {}
        )
      end
    rescue => e
      # Log the error
      Rails.logger.error("Failed to record LLM cost: #{e.message}")
      
      # Report to error tracking service
      ErrorReporter.report(e, 
        extra: { cost_data: cost_data, context: context }
      )
      
      # Queue a background job to retry later
      LLMCostRecordingJob.perform_later(cost_data, context)
    end
  end
end

# app/jobs/llm_cost_recording_job.rb
class LLMCostRecordingJob < ApplicationJob
  queue_as :default
  
  def perform(cost_data, context)
    LLMCostLog.create!(
      request_type: context[:request_type],
      llm_model_name: context[:model_name],
      prompt_tokens: cost_data[:prompt_tokens],
      completion_tokens: cost_data[:completion_tokens],
      total_tokens: cost_data[:total_tokens],
      cost: cost_data[:total_cost],
      user: context[:user],
      trackable: context[:trackable],
      metadata: context[:metadata] || {}
    )
  rescue => e
    # Final fallback: log to a dedicated error log
    Rails.logger.error("CRITICAL: Failed to record LLM cost after retry: #{e.message}")
    
    # Write to a dedicated log file as last resort
    File.open(Rails.root.join('log', 'failed_llm_costs.log'), 'a') do |file|
      file.puts({
        time: Time.current,
        error: e.message,
        cost_data: cost_data,
        context: context
      }.to_json)
    end
  end
end
```

Benefits:
- Immediate retries for transient database issues
- Background job for persistent failures
- Multiple layers of fallback
- Comprehensive error reporting and logging

## Implementation Plan

To implement these improvements while minimizing disruption, a phased approach is recommended:

### Phase 1: Extract Service Objects (1-2 weeks)
1. Create the `LLMCostCalculator` service to handle cost calculations
2. Create the `LLMCostTracker` service to handle log recording
3. Update the existing `CostTracking` module to use these services
4. Add comprehensive tests for the new services

### Phase 2: Implement Configuration Model (1 week)
1. Create the `LLMPricingConfig` model and migration
2. Seed initial pricing data from current hardcoded values
3. Update the `LLMCostCalculator` to use the pricing configuration
4. Create an admin interface for managing pricing

### Phase 3: Improve Error Handling (1 week)
1. Implement the retry logic for cost recording
2. Create the background job for persistent failures
3. Add comprehensive logging and error reporting
4. Test failure scenarios thoroughly

### Phase 4: Implement Request Objects (1-2 weeks)
1. Create the `LLMRequest` model for validating and standardizing requests
2. Update client interfaces to accept the new request objects
3. Create adapter classes for backward compatibility
4. Update documentation and examples for the new interface

### Phase 5: Provider-Specific Adapters (1 week)
1. Create the adapter base class and factory
2. Implement provider-specific adapters for each LLM provider
3. Update the cost tracking service to use the adapters
4. Add tests for each adapter

### Phase 6: Event System (1-2 weeks)
1. Implement the event publisher/subscriber system
2. Update the client implementations to publish events
3. Convert the cost tracking to use events
4. Gradually migrate existing code to the new system

### Phase 7: Dependency Injection (1 week)
1. Update the `ClientFactory` to use explicit decoration
2. Remove monkey patching in the initializer
3. Update configuration to use the new approach
4. Test thoroughly with different configurations

## Metrics for Success

To measure the success of the refactoring, the following metrics should be tracked:

1. **Code Quality**:
   - Reduction in cyclomatic complexity
   - Improved test coverage
   - Fewer dependencies between components

2. **System Reliability**:
   - Reduced error rates in cost tracking
   - Improved error recovery
   - Consistent cost data in the database

3. **Maintainability**:
   - Time required to add support for new LLM providers
   - Ease of updating pricing information
   - Developer feedback on system clarity

4. **Performance**:
   - Impact on request latency from cost tracking
   - Database query performance for cost reports
   - Memory usage of the cost tracking system

## Conclusion

The current LLM cost tracking system effectively serves its core purpose but can benefit from architectural improvements to enhance maintainability, flexibility, and reliability. By implementing the suggested refactorings in a phased approach, the system can evolve into a more robust and extensible solution without disrupting existing functionality.

The key principles guiding these refactorings are:
- Clear separation of responsibilities
- Explicit interfaces and configurations
- Reduced coupling between components
- Improved error handling and reliability
- Better adherence to design patterns and principles

These improvements will position the system to better accommodate future changes, such as new LLM providers, pricing models, or reporting requirements, while maintaining the core functionality that makes it valuable. 