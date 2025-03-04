# LLM Cost Tracking Implementation Plan

## Problem Statement

We need to track the cost of LLM (Large Language Model) API calls in our application to:

1. Monitor usage and expenses by user
2. Analyze costs by request type (grading, feedback, etc.)
3. Associate costs with specific objects (GradingTask, StudentSubmission, etc.)
4. Generate reports on usage patterns and cost distribution
5. Maintain a clean separation of concerns in our architecture

The challenge is implementing this tracking without polluting our LLM client with domain-specific knowledge or tightly coupling it to our application models.

## Proposed Solution: Hybrid Approach

We will implement a hybrid solution combining a decorator pattern with a dedicated tracking module. This provides:

1. Full separation of concerns - LLM client remains focused on API interactions
2. Flexibility - both automatic and manual tracking options
3. Explicit control - clear when and how tracking occurs
4. Independent evolvability - components can change without affecting each other

## Architecture Overview

![Architecture Diagram](https://mermaid.ink/img/pako:eNqNkk9PwzAMxb9KlHMr9Q9wQZrYBhICcYCLlbixomZJSJxpVdXvjttukNEJwSnO8_Ozn53bwsUxBR8sVi1eW1xBdBhZ4Wl9FOo9Xns8iyPGrCOGSRpfcSAJnM-GIDV3mFjNn6C4b7lnjdZE1_-S29zfFSM_9bX5Q3yD4JEw5cFGUXO_qjuTJMmV8dLZh2B7rnpYRTYnm05iBIkJDjLXc0I2WI2YJC9JnDnEhq4zXGy7yDCgQPH9qOiYkkN2OECiJAPw-WaehXVmMtacrEp0KplWw7XnXPKFTw7jfY7qgI67Ds6jpbPw7FZBtgPGM5HuXB06SJDqKdfFrsCmqhR-RK1VQ1BTc7Ir8XYGNS1hnR-_Sp5jV9bZo4OxuICyeIFbmGEAd23dCcw0VebgbzOuJZRvmPM9TC8P0P4COAUwrg?type=png)

## Components

1. **LlmCostLog Model**: Database model for storing cost data
2. **LlmCostTracking Module**: Encapsulates cost tracking logic
3. **CostTrackingDecorator**: Wraps LLM client for automatic tracking
4. **Database Migration**: Creates the necessary table structure

## Implementation Steps

### Step 1: Create Database Table

```ruby
# db/migrate/YYYYMMDDHHMMSS_create_llm_cost_logs.rb
class CreateLlmCostLogs < ActiveRecord::Migration[7.0]
  def change
    create_table :llm_cost_logs do |t|
      t.references :user, foreign_key: true, null: true
      t.references :trackable, polymorphic: true, null: true
      t.string :request_type
      t.string :model_name
      t.integer :prompt_tokens
      t.integer :completion_tokens
      t.integer :total_tokens
      t.decimal :cost, precision: 10, scale: 6
      t.string :request_id, index: true
      t.jsonb :metadata

      t.timestamps
    end

    add_index :llm_cost_logs, :request_type
    add_index :llm_cost_logs, :model_name
    add_index :llm_cost_logs, :created_at
  end
end
```

### Step 2: Create LlmCostLog Model

```ruby
# app/models/llm_cost_log.rb
class LlmCostLog < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :trackable, polymorphic: true, optional: true

  validates :model_name, presence: true
  validates :cost, numericality: { greater_than_or_equal_to: 0 }
  
  # Scopes for querying
  scope :for_user, ->(user) { where(user: user) }
  scope :for_request_type, ->(type) { where(request_type: type) }
  scope :for_model, ->(model) { where(model_name: model) }
  scope :for_date_range, ->(start_date, end_date) { where(created_at: start_date..end_date) }
  scope :for_trackable, ->(trackable) { where(trackable: trackable) }
  
  # Reporting methods
  def self.total_cost(scope = all)
    scope.sum(:cost)
  end
  
  def self.cost_breakdown_by_type
    group(:request_type).sum(:cost)
  end
  
  def self.cost_breakdown_by_model
    group(:model_name).sum(:cost)
  end
  
  def self.cost_breakdown_by_user
    joins(:user).group('users.email').sum(:cost)
  end
  
  def self.daily_costs(days = 30)
    where('created_at >= ?', days.days.ago)
      .group("DATE(created_at)")
      .sum(:cost)
  end
end
```

### Step 3: Create LlmCostTracking Module

```ruby
# lib/llm/cost_tracking.rb
module LLM
  module CostTracking
    # Generates a tracking context hash for an LLM request
    def self.generate_context(request_type: nil, trackable: nil, user: nil, metadata: {})
      {
        request_id: SecureRandom.uuid,
        request_type: request_type,
        trackable: trackable,
        user: user,
        metadata: metadata || {}
      }
    end
    
    # Records cost data to the database
    def self.record(cost_data, context = {})
      LlmCostLog.create!(
        user: context[:user],
        trackable: context[:trackable],
        request_type: context[:request_type],
        request_id: context[:request_id] || cost_data[:request_id],
        model_name: cost_data[:model_name],
        prompt_tokens: cost_data[:prompt_tokens],
        completion_tokens: cost_data[:completion_tokens],
        total_tokens: cost_data[:total_tokens],
        cost: cost_data[:cost],
        metadata: context[:metadata]
      )
    rescue => e
      Rails.logger.error "Failed to record LLM cost: #{e.message}"
      # Optionally, enqueue a retry job or alert
    end
    
    # Calculate cost based on model and token usage
    # This could be extended with more sophisticated pricing logic
    def self.calculate_cost(model_name, prompt_tokens, completion_tokens)
      rates = pricing_rates[model_name.to_s] || default_rate
      
      prompt_cost = prompt_tokens * rates[:prompt]
      completion_cost = completion_tokens * rates[:completion]
      
      (prompt_cost + completion_cost).round(6)
    end
    
    # Current pricing rates per 1K tokens (as of March 2024)
    # Should be updated as pricing changes
    def self.pricing_rates
      {
        'claude-3-opus' => { prompt: 0.015, completion: 0.075 },
        'claude-3-sonnet' => { prompt: 0.003, completion: 0.015 },
        'claude-3-haiku' => { prompt: 0.00025, completion: 0.00125 },
        # Add other models as needed
      }
    end
    
    def self.default_rate
      { prompt: 0.01, completion: 0.03 }
    end
  end
end
```

### Step 4: Create CostTrackingDecorator

```ruby
# lib/llm/cost_tracking_decorator.rb
module LLM
  class CostTrackingDecorator
    attr_reader :client
    
    def initialize(client)
      @client = client
    end
    
    def execute_request(input_object)
      # Extract context from options
      context = input_object[:context] || {}
      context[:request_id] ||= SecureRandom.uuid
      
      # Execute the original request
      response = client.execute_request(input_object)
      
      # Extract token usage from response
      if response.is_a?(Hash) && response[:metadata]
        tokens = response[:metadata][:tokens] || {}
        
        # Calculate cost
        cost_data = {
          model_name: client.model_name,
          prompt_tokens: tokens[:prompt] || 0,
          completion_tokens: tokens[:completion] || 0,
          total_tokens: tokens[:total] || 0,
          cost: response[:metadata][:cost] || 
                CostTracking.calculate_cost(
                  client.model_name,
                  tokens[:prompt] || 0,
                  tokens[:completion] || 0
                ),
          request_id: context[:request_id]
        }
        
        # Record cost data
        CostTracking.record(cost_data, context)
      end
      
      # Return original response
      response
    end
    
    # Delegate all other methods to the wrapped client
    def method_missing(method, *args, &block)
      client.send(method, *args, &block)
    end
    
    def respond_to_missing?(method, include_private = false)
      client.respond_to?(method, include_private) || super
    end
  end
end
```

### Step 5: Configure Initialization

```ruby
# config/initializers/llm.rb
require 'llm/cost_tracking'
require 'llm/cost_tracking_decorator'

Rails.application.config.to_prepare do
  # Any global configuration for LLM cost tracking
end
```

## Usage Examples

### Example 1: Automatic Tracking with Decorator

```ruby
# app/services/grading_service.rb
def grade_submission(submission, user)
  # Get the base LLM client
  llm_client = LLM::Anthropic::Client.new("claude-3-sonnet")
  
  # Wrap with cost tracking decorator
  tracked_client = LLM::CostTrackingDecorator.new(llm_client)
  
  # Prepare context for tracking
  context = LLM::CostTracking.generate_context(
    request_type: "submission_grading",
    trackable: submission,
    user: user,
    metadata: {
      assignment_name: submission.grading_task.assignment.name,
      course_name: submission.grading_task.assignment.course.name
    }
  )
  
  # Execute request with tracking
  response = tracked_client.execute_request(
    prompt: build_prompt(submission),
    context: context
  )
  
  # Process response
  process_grading_response(response)
end
```

### Example 2: Manual Tracking

```ruby
# app/services/feedback_service.rb
def generate_summary_feedback(student, assignment, user)
  # Get the base LLM client
  llm_client = LLM::Anthropic::Client.new("claude-3-haiku")
  
  # Generate tracking context
  context = LLM::CostTracking.generate_context(
    request_type: "summary_feedback",
    trackable: assignment,
    user: user,
    metadata: { student_id: student.id }
  )
  
  # Make the request without automatic tracking
  response = llm_client.execute_request(prompt: build_prompt(student, assignment))
  
  # Get token usage from response
  tokens = response[:metadata][:tokens] || {}
  
  # Manually record the cost
  cost_data = {
    model_name: llm_client.model_name,
    prompt_tokens: tokens[:prompt] || 0,
    completion_tokens: tokens[:completion] || 0,
    total_tokens: tokens[:total] || 0,
    cost: LLM::CostTracking.calculate_cost(
      llm_client.model_name,
      tokens[:prompt] || 0, 
      tokens[:completion] || 0
    ),
    request_id: context[:request_id]
  }
  
  # Record cost data
  LLM::CostTracking.record(cost_data, context)
  
  # Return processed response
  process_feedback_response(response)
end
```

### Example 3: Generating Cost Reports

```ruby
# app/controllers/admin/cost_reports_controller.rb
class Admin::CostReportsController < AdminController
  def index
    @total_cost = LlmCostLog.total_cost
    @cost_by_type = LlmCostLog.cost_breakdown_by_type
    @cost_by_model = LlmCostLog.cost_breakdown_by_model
    @daily_costs = LlmCostLog.daily_costs(30)
    @top_users = LlmCostLog.cost_breakdown_by_user.sort_by(&:last).reverse.first(10)
  end
  
  def user_costs
    @user = User.find(params[:user_id])
    @costs = LlmCostLog.for_user(@user)
    @total_cost = @costs.total_cost
    @cost_by_type = @costs.cost_breakdown_by_type
    @cost_by_model = @costs.cost_breakdown_by_model
    @daily_costs = @costs.where('created_at >= ?', 30.days.ago)
                        .group("DATE(created_at)")
                        .sum(:cost)
  end
  
  def export_csv
    respond_to do |format|
      format.csv do
        # Generate CSV export of cost data
      end
    end
  end
end
```

## Testing Strategy

### 1. Unit Tests for Core Components

```ruby
# test/lib/llm/cost_tracking_test.rb
require 'test_helper'

class LLM::CostTrackingTest < ActiveSupport::TestCase
  def test_calculates_cost_correctly_for_claude_3_opus
    cost = LLM::CostTracking.calculate_cost('claude-3-opus', 1000, 500)
    expected = (1000 * 0.015/1000) + (500 * 0.075/1000)
    assert_equal expected.round(6), cost
  end
  
  def test_uses_default_rates_for_unknown_models
    cost = LLM::CostTracking.calculate_cost('unknown-model', 1000, 500)
    expected = (1000 * 0.01/1000) + (500 * 0.03/1000)
    assert_equal expected.round(6), cost
  end
  
  def test_handles_zero_tokens_gracefully
    cost = LLM::CostTracking.calculate_cost('claude-3-sonnet', 0, 0)
    assert_equal 0.0, cost
  end
  
  def test_calculates_cost_correctly_for_all_supported_models
    LLM::CostTracking.pricing_rates.each do |model_name, rates|
      prompt_tokens = 1000
      completion_tokens = 500
      expected = (prompt_tokens * rates[:prompt]/1000) + (completion_tokens * rates[:completion]/1000)
      assert_equal expected.round(6), LLM::CostTracking.calculate_cost(model_name, prompt_tokens, completion_tokens)
    end
  end
  
  def test_generates_complete_context_with_all_parameters
    user = users(:admin)
    submission = student_submissions(:one)
    
    context = LLM::CostTracking.generate_context(
      request_type: 'test',
      trackable: submission,
      user: user,
      metadata: { custom: 'value' }
    )
    
    refute_nil context[:request_id]
    assert_equal 'test', context[:request_type]
    assert_equal submission, context[:trackable]
    assert_equal user, context[:user]
    assert_equal({ custom: 'value' }, context[:metadata])
  end
  
  def test_generates_uuid_for_request_id
    context = LLM::CostTracking.generate_context
    assert_match(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/, context[:request_id])
  end
  
  def test_handles_nil_parameters_in_context_generation
    context = LLM::CostTracking.generate_context
    assert_nil context[:request_type]
    assert_nil context[:trackable]
    assert_nil context[:user]
    assert_equal({}, context[:metadata])
  end
  
  def test_creates_cost_log_record_with_full_data
    user = users(:admin)
    submission = student_submissions(:one)
    
    context = {
      request_type: 'test',
      trackable: submission,
      user: user,
      request_id: 'test-123',
      metadata: { test: true }
    }
    
    cost_data = {
      model_name: 'claude-3-sonnet',
      prompt_tokens: 100,
      completion_tokens: 50,
      total_tokens: 150,
      cost: 0.00225
    }
    
    assert_difference -> { LlmCostLog.count }, 1 do
      LLM::CostTracking.record(cost_data, context)
    end
    
    log = LlmCostLog.last
    assert_equal user, log.user
    assert_equal submission, log.trackable
    assert_equal 'test', log.request_type
    assert_equal 'claude-3-sonnet', log.model_name
    assert_equal 100, log.prompt_tokens
    assert_equal 50, log.completion_tokens
    assert_equal 150, log.total_tokens
    assert_equal 0.00225, log.cost
    assert_equal 'test-123', log.request_id
    assert_equal({ 'test' => true }, log.metadata)
  end
  
  def test_works_with_minimal_data
    minimal_data = { model_name: 'claude-3-haiku', cost: 0.001 }
    
    assert_difference -> { LlmCostLog.count }, 1 do
      LLM::CostTracking.record(minimal_data)
    end
    
    log = LlmCostLog.last
    assert_equal 'claude-3-haiku', log.model_name
    assert_equal 0.001, log.cost
  end
  
  def test_logs_errors_but_does_not_raise_them
    cost_data = { model_name: 'claude-3-sonnet', cost: 0.001 }
    context = { request_type: 'test' }
    
    LlmCostLog.stub :create!, -> (*args) { raise "Database error" } do
      Rails.logger.expects(:error).with(regexp_matches(/Failed to record LLM cost: Database error/))
      
      # Should not raise an error
      LLM::CostTracking.record(cost_data, context)
    end
  end
end
```

### 2. Unit Tests for LlmCostLog Model

```ruby
# test/models/llm_cost_log_test.rb
require 'test_helper'

class LlmCostLogTest < ActiveSupport::TestCase
  def test_validations
    # Model name must be present
    log = LlmCostLog.new(cost: 0.01)
    refute log.valid?
    assert_includes log.errors.full_messages, "Model name can't be blank"
    
    # Cost must be non-negative
    log = LlmCostLog.new(model_name: 'claude-3-sonnet', cost: -1)
    refute log.valid?
    assert_includes log.errors.full_messages, "Cost must be greater than or equal to 0"
    
    # Valid log
    log = LlmCostLog.new(model_name: 'claude-3-sonnet', cost: 0.01)
    assert log.valid?
  end
  
  def test_associations
    # User is optional
    log = LlmCostLog.new(model_name: 'claude-3-sonnet', cost: 0.01)
    assert log.valid?
    
    # Can be associated with a user
    log.user = users(:admin)
    assert log.valid?
    
    # Trackable is optional
    log = LlmCostLog.new(model_name: 'claude-3-sonnet', cost: 0.01)
    assert log.valid?
    
    # Can be associated with a trackable
    log.trackable = student_submissions(:one)
    assert log.valid?
  end
  
  def setup_log_data
    # Create users
    user1 = users(:teacher)
    user2 = users(:admin)
    submission = student_submissions(:one)
    
    # Create logs
    LlmCostLog.create!(
      user: user1, 
      request_type: 'grading', 
      model_name: 'claude-3-sonnet', 
      cost: 0.01, 
      created_at: 1.day.ago
    )
    
    LlmCostLog.create!(
      user: user1, 
      request_type: 'feedback', 
      model_name: 'claude-3-haiku', 
      cost: 0.02, 
      created_at: 2.days.ago
    )
    
    LlmCostLog.create!(
      user: user2, 
      request_type: 'grading', 
      model_name: 'claude-3-sonnet', 
      cost: 0.03, 
      created_at: 3.days.ago
    )
    
    LlmCostLog.create!(
      user: user2, 
      request_type: 'summary', 
      model_name: 'claude-3-opus', 
      cost: 0.04, 
      trackable: submission, 
      created_at: 4.days.ago
    )
  end
  
  def test_scope_for_user
    setup_log_data
    
    user = users(:teacher)
    logs = LlmCostLog.for_user(user)
    
    assert_equal 2, logs.count
    logs.each do |log|
      assert_equal user, log.user
    end
  end
  
  def test_scope_for_request_type
    setup_log_data
    
    logs = LlmCostLog.for_request_type('grading')
    
    assert_equal 2, logs.count
    logs.each do |log|
      assert_equal 'grading', log.request_type
    end
  end
  
  def test_scope_for_model
    setup_log_data
    
    logs = LlmCostLog.for_model('claude-3-sonnet')
    
    assert_equal 2, logs.count
    logs.each do |log|
      assert_equal 'claude-3-sonnet', log.model_name
    end
  end
  
  def test_scope_for_date_range
    setup_log_data
    
    logs = LlmCostLog.for_date_range(3.days.ago, 1.day.ago)
    
    assert_equal 3, logs.count
    logs.each do |log|
      assert log.created_at >= 3.days.ago
      assert log.created_at <= 1.day.ago
    end
  end
  
  def test_scope_for_trackable
    setup_log_data
    
    trackable = student_submissions(:one)
    logs = LlmCostLog.for_trackable(trackable)
    
    assert_equal 1, logs.count
    assert_equal trackable, logs.first.trackable
  end
  
  def setup_reporting_data
    user1 = users(:teacher)
    user2 = users(:admin)
    
    LlmCostLog.create!(
      user: user1, 
      request_type: 'grading', 
      model_name: 'claude-3-sonnet', 
      cost: 0.01, 
      created_at: 1.day.ago
    )
    
    LlmCostLog.create!(
      user: user1, 
      request_type: 'feedback', 
      model_name: 'claude-3-haiku', 
      cost: 0.02, 
      created_at: 2.days.ago
    )
    
    LlmCostLog.create!(
      user: user2, 
      request_type: 'grading', 
      model_name: 'claude-3-sonnet', 
      cost: 0.03, 
      created_at: 3.days.ago
    )
    
    LlmCostLog.create!(
      user: user2, 
      request_type: 'summary', 
      model_name: 'claude-3-opus', 
      cost: 0.04, 
      created_at: 4.days.ago
    )
  end
  
  def test_total_cost
    setup_reporting_data
    
    assert_equal 0.1, LlmCostLog.total_cost
  end
  
  def test_total_cost_respects_scope
    setup_reporting_data
    
    assert_equal 0.04, LlmCostLog.for_request_type('grading').total_cost
  end
  
  def test_cost_breakdown_by_type
    setup_reporting_data
    
    breakdown = LlmCostLog.cost_breakdown_by_type
    assert_equal 0.04, breakdown['grading']
    assert_equal 0.02, breakdown['feedback']
    assert_equal 0.04, breakdown['summary']
  end
  
  def test_cost_breakdown_by_model
    setup_reporting_data
    
    breakdown = LlmCostLog.cost_breakdown_by_model
    assert_equal 0.04, breakdown['claude-3-sonnet']
    assert_equal 0.02, breakdown['claude-3-haiku']
    assert_equal 0.04, breakdown['claude-3-opus']
  end
  
  def test_cost_breakdown_by_user
    setup_reporting_data
    
    breakdown = LlmCostLog.cost_breakdown_by_user
    teacher_email = users(:teacher).email
    admin_email = users(:admin).email
    
    assert_equal 0.03, breakdown[teacher_email]
    assert_equal 0.07, breakdown[admin_email]
  end
  
  def test_daily_costs
    setup_reporting_data
    
    daily = LlmCostLog.daily_costs(7)
    assert_equal 4, daily.keys.count
    assert_equal 0.1, daily.values.sum
  end
  
  def test_daily_costs_respects_days_parameter
    setup_reporting_data
    
    assert_equal 2, LlmCostLog.daily_costs(2).keys.count
  end
end
```

### 3. Integration Tests for CostTrackingDecorator

```ruby
# test/lib/llm/cost_tracking_decorator_test.rb
require 'test_helper'

class LLM::CostTrackingDecoratorTest < ActiveSupport::TestCase
  def setup
    @client = Minitest::Mock.new
    def @client.model_name; 'claude-3-sonnet'; end
    
    @decorator = LLM::CostTrackingDecorator.new(@client)
    @user = users(:teacher)
    @submission = student_submissions(:one)
    
    @response = {
      content: 'Test response',
      metadata: {
        tokens: {
          prompt: 100,
          completion: 50,
          total: 150
        },
        cost: 0.00225
      }
    }
    
    @input_object = {
      prompt: 'Test prompt',
      context: {
        request_type: 'test',
        trackable: @submission,
        user: @user,
        metadata: { test: true }
      }
    }
  end
  
  def test_passes_the_request_to_the_original_client
    @client.expect :execute_request, @response, [@input_object]
    
    @decorator.execute_request(@input_object)
    @client.verify
  end
  
  def test_creates_a_cost_log_record
    @client.expect :execute_request, @response, [@input_object]
    
    assert_difference -> { LlmCostLog.count }, 1 do
      @decorator.execute_request(@input_object)
    end
    
    log = LlmCostLog.last
    assert_equal @user, log.user
    assert_equal @submission, log.trackable
    assert_equal 'test', log.request_type
    assert_equal 'claude-3-sonnet', log.model_name
    assert_equal 100, log.prompt_tokens
    assert_equal 50, log.completion_tokens
    assert_equal 150, log.total_tokens
    assert_equal 0.00225, log.cost
  end
  
  def test_returns_the_original_response
    @client.expect :execute_request, @response, [@input_object]
    
    result = @decorator.execute_request(@input_object)
    assert_equal @response, result
  end
  
  def test_handles_missing_token_information
    response_without_tokens = {
      content: 'Test response',
      metadata: {}
    }
    @client.expect :execute_request, response_without_tokens, [@input_object]
    
    assert_difference -> { LlmCostLog.count }, 1 do
      @decorator.execute_request(@input_object)
    end
    
    log = LlmCostLog.last
    assert_equal 0, log.prompt_tokens
    assert_equal 0, log.completion_tokens
    assert_equal 0, log.total_tokens
  end
  
  def test_handles_missing_context
    input_without_context = { prompt: 'Test prompt' }
    @client.expect :execute_request, @response, [input_without_context]
    
    assert_difference -> { LlmCostLog.count }, 1 do
      @decorator.execute_request(input_without_context)
    end
    
    log = LlmCostLog.last
    assert_nil log.request_type
    assert_nil log.trackable
    assert_nil log.user
  end
  
  def test_handles_responses_without_metadata
    response_without_metadata = { content: 'Test response' }
    @client.expect :execute_request, response_without_metadata, [@input_object]
    
    assert_no_difference -> { LlmCostLog.count } do
      @decorator.execute_request(@input_object)
    end
  end
  
  def test_delegates_unknown_methods_to_client
    @client.expect :some_method, 'result', []
    
    assert_equal 'result', @decorator.some_method
    @client.verify
  end
  
  def test_responds_to_client_methods
    @client.expect :respond_to?, true, [:some_method, false]
    
    assert @decorator.respond_to?(:some_method)
    @client.verify
  end
end
```

### 4. Mock-Based Tests for Service Integration

```ruby
# test/services/grading_service_test.rb
require 'test_helper'

class GradingServiceTest < ActiveSupport::TestCase
  def setup
    @service = GradingService.new
    @submission = student_submissions(:one)
    @user = users(:teacher)
    
    @response = {
      content: JSON.generate({
        feedback: "Good work!",
        strengths: ["Clear explanations", "Good structure"],
        opportunities: ["Improve examples", "Add more detail"],
        overall_grade: "B+",
        rubric_scores: { "clarity": 4, "content": 3 }
      }),
      metadata: {
        tokens: { prompt: 1000, completion: 500, total: 1500 },
        cost: 0.015
      }
    }
    
    # Setup mocks
    @llm_client = Minitest::Mock.new
    @tracked_client = Minitest::Mock.new
    
    # Store original methods to restore after test
    @original_new = LLM::Anthropic::Client.method(:new)
    @original_decorator_new = LLM::CostTrackingDecorator.method(:new)
    @original_generate_context = LLM::CostTracking.method(:generate_context)
    
    # Replace with mocks
    LLM::Anthropic::Client.define_singleton_method(:new) do |*args|
      @llm_client
    end
    
    LLM::CostTrackingDecorator.define_singleton_method(:new) do |client|
      raise "Wrong client" unless client == @llm_client
      @tracked_client
    end
    
    LLM::CostTracking.define_singleton_method(:generate_context) do |**kwargs|
      @context_args = kwargs
      {}
    end
  end
  
  def teardown
    # Restore original methods
    LLM::Anthropic::Client.define_singleton_method(:new, @original_new)
    LLM::CostTrackingDecorator.define_singleton_method(:new, @original_decorator_new)
    LLM::CostTracking.define_singleton_method(:generate_context, @original_generate_context)
  end
  
  def test_wraps_llm_client_with_cost_tracking_decorator
    @tracked_client.expect :execute_request, @response, [Hash]
    
    @service.grade_submission(@submission, @user)
    @tracked_client.verify
  end
  
  def test_generates_tracking_context_with_correct_parameters
    @tracked_client.expect :execute_request, @response, [Hash]
    
    @service.grade_submission(@submission, @user)
    
    assert_equal "submission_grading", @context_args[:request_type]
    assert_equal @submission, @context_args[:trackable]
    assert_equal @user, @context_args[:user]
  end
  
  def test_executes_request_with_tracking_context
    @tracked_client.expect :execute_request, @response do |arg|
      arg.key?(:context)
    end
    
    @service.grade_submission(@submission, @user)
    @tracked_client.verify
  end
end
```

### 5. Test Fixtures for Testing

```ruby
# test/fixtures/llm_cost_logs.yml
log_one:
  model_name: claude-3-sonnet
  prompt_tokens: 1000
  completion_tokens: 500
  total_tokens: 1500
  cost: 0.01
  request_type: grading
  request_id: <%= SecureRandom.uuid %>
  user: teacher
  
log_two:
  model_name: claude-3-haiku
  prompt_tokens: 500
  completion_tokens: 200
  total_tokens: 700
  cost: 0.005
  request_type: feedback
  request_id: <%= SecureRandom.uuid %>
  user: teacher
  trackable: student_submissions_one (StudentSubmission)
  
log_three:
  model_name: claude-3-opus
  prompt_tokens: 2000
  completion_tokens: 1000
  total_tokens: 3000
  cost: 0.05
  request_type: grading
  request_id: <%= SecureRandom.uuid %>
  user: admin
  created_at: <%= 2.days.ago %>
  
# Add other fixtures as needed: users, student_submissions, etc.
```

This comprehensive Minitest approach ensures:

1. **Faster Testing**: Minitest is typically faster than RSpec
2. **Simplicity**: Tests are straightforward and follow a consistent pattern
3. **Error Handling**: Edge cases are thoroughly tested
4. **Integration Points**: Components are verified to work together
5. **High Coverage**: All code paths are tested
6. **Consistency**: Tests follow Rails conventions

Minitest provides all the necessary tools for thorough testing without the overhead of a DSL, keeping tests fast and focused while ensuring comprehensive coverage of the cost tracking functionality.

## Implementation Timeline

1. **step 1**: Set up database and models
   - Create database migration
   - Implement LlmCostLog model
   - Write comprehensive unit tests for the model

2. **step 2**: Implement core tracking logic
   - Create CostTracking module
   - Implement CostTrackingDecorator
   - Write unit and integration tests for both components

3. **step 3**: Service integration
   - Update GradingService to use cost tracking
   - Update other services that use LLM
   - Write mock-based tests for service integration

4. **step 4**: Reporting and admin interface
   - Implement admin reports controller
   - Create reporting methods on the LlmCostLog model
   - Write unit tests for reporting functionality

## Conclusion

This hybrid approach provides a clean, modular solution for LLM cost tracking that:

1. Maintains separation of concerns
2. Provides flexibility through both automatic and manual tracking
3. Offers comprehensive reporting capabilities
4. Can evolve independently from the core LLM client
5. Follows good design practices

The implementation can be rolled out incrementally, starting with the core infrastructure and gradually integrating with all LLM-using services. 