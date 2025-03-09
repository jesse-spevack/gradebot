# LLM Cost Tracking Usage Guide

This guide explains how to use the LLM cost tracking system implemented in our application.

## Overview

The LLM cost tracking system allows you to:

1. Automatically track costs for all LLM API calls
2. Manually track costs when needed
3. Generate reports on LLM usage and costs
4. Associate costs with users, request types, and application objects

## Automatic Cost Tracking

By default, all LLM clients created through the `LLM::ClientFactory` are automatically wrapped with cost tracking. This means you don't need to do anything special to track costs.

```ruby
# The client returned is already wrapped with cost tracking
client = LLM::ClientFactory.create_client(:anthropic)

# Use the client normally - costs are tracked automatically
response = client.execute_request({
  prompt: "Hello, world!",
  context: {
    request_type: "greeting",
    user: current_user,
    trackable: @assignment
  }
})
```

### Disabling Automatic Tracking

If you want to disable automatic tracking globally, you can set the configuration in an initializer:

```ruby
# In config/application.rb or an environment file
config.x.llm.auto_track_costs = false
```

## Manual Cost Tracking

### Manual Decoration

If you have a client instance that isn't automatically wrapped, you can manually decorate it:

```ruby
# Create or obtain an LLM client
raw_client = SomeExternalLlmClient.new

# Wrap it with cost tracking
tracking_client = LLM::CostTrackingInitializer.decorate_client(raw_client)

# Use the wrapped client
tracking_client.execute_request(input_object)
```

### Manual Cost Recording

If you need to record costs manually (e.g., for external API calls or batch processing), you can use the `CostTracking` module directly:

```ruby
# Generate a tracking context
context = LLM::CostTracking.generate_context(
  request_type: "batch_processing",
  user: admin_user,
  trackable: @batch_job,
  metadata: { source: "external_provider" }
)

# Record the cost
LLM::CostTracking.record(
  model_name: "gpt-4",
  prompt_tokens: 1200,
  completion_tokens: 500,
  total_tokens: 1700,
  cost: 0.034,  # If you know the exact cost
  context: context
)
```

## Context Information

To associate costs with your application entities, include the relevant information in the `context` hash:

| Field | Description | Example |
|-------|-------------|---------|
| `request_type` | The type/purpose of the request | `"grading"`, `"feedback"`, `"summary"` |
| `user` | The user making the request | `current_user` |
| `trackable` | The object associated with the request | `@submission`, `@assignment` |
| `metadata` | Any additional information (stored as JSON) | `{ priority: "high", retry: 2 }` |

## Generating Cost Reports

You can generate reports on LLM usage and costs directly from the `LLMCostLog` model:

```ruby
# Generate a daily cost report for the last 30 days
report = LLMCostLog.generate_report(
  start_date: 30.days.ago,
  group_by: :day
)

# Generate a report of costs by user
user_report = LLMCostLog.generate_report(
  start_date: 30.days.ago,
  group_by: :user
)

# Generate a report of costs by model
model_report = LLMCostLog.generate_report(
  start_date: 30.days.ago,
  group_by: :model
)

# Generate a report of costs by request type
type_report = LLMCostLog.generate_report(
  start_date: 30.days.ago,
  group_by: :request_type
)
```

## Direct Access to Cost Data

For more specific data needs, you can use the `LLMCostLog` model directly:

```ruby
# Get logs for the current user
user_logs = LLMCostLog.for_user(current_user)

# Get logs for a specific trackable object
assignment_logs = LLMCostLog.for_trackable(@assignment)

# Get logs for a specific request type
feedback_logs = LLMCostLog.for_request_type("feedback")

# Calculate cost for a specific model
opus_cost = LLMCostLog.for_model("claude-3-opus").sum(:cost)
```

## Best Practices

1. **Always include request context**: Provide as much context as possible when making requests to enable better reporting.
2. **Use consistent request types**: Standardize your request_type values across the application.
3. **Associate with trackable objects**: Link costs to business objects when possible.
4. **Monitor regularly**: Check reports periodically to understand usage patterns and optimize costs.
5. **Add indexes**: If you have heavy query needs, consider adding database indexes for frequently queried fields.

## Troubleshooting

### Missing Costs

If costs aren't being recorded:

1. Check that the response contains token usage information
2. Verify that the client is properly decorated with the CostTrackingDecorator
3. Ensure that the required context information is provided in the request

### Database Performance

If you experience performance issues with a large number of logs:

1. Consider implementing log rotation or archiving for older records
2. Add appropriate indexes for your most common queries
3. Use database partitioning for very large datasets 