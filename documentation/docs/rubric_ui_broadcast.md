# Rubric UI Broadcasting

This document explains how the real-time UI updates for Rubrics work in GradeBot.

## Overview

The `Rubric::BroadcasterService` is responsible for real-time UI updates when a rubric's status changes. It uses Turbo Streams to push updates to the browser without requiring a page refresh.

## How It Works

1. When a rubric's status changes (e.g., from "pending" to "processing" or "complete"), the broadcaster service is triggered
2. The service broadcasts updates to two DOM elements:
   - The rubric container (full card)
   - The rubric status badge (just the status indicator)
3. Any client subscribed to the rubric's channel receives these updates
4. The DOM is automatically updated via Turbo Streams

## Technical Implementation

### Channel Name

Each rubric has its own dedicated Turbo Stream channel based on its ID:

```ruby
def channel_name
  "rubric_#{rubric.id}"
```

### DOM Targets

The service updates two specific DOM elements:

```ruby
def container_dom_id
  "rubric_container_#{rubric.id}"
end

def status_badge_dom_id
  "rubric_status_badge_#{rubric.id}"
end
```

### Broadcasting Process

The service uses Turbo Streams to replace specific DOM elements with freshly rendered partials:

```ruby
Turbo::StreamsChannel.broadcast_replace_to(
  channel_name,
  target: target,
  partial: partial,
  locals: locals
)
```

## Usage Examples

### From a Service

```ruby
# Inside a service after changing a rubric's status
def process_rubric(rubric)
  # Process the rubric...
  rubric.update(status: :complete)
  
  # Broadcast the update to the UI
  Rubric::BroadcasterService.broadcast(rubric)
end
```

### From a Job

```ruby
# Inside a background job
def perform(rubric_id)
  rubric = Rubric.find(rubric_id)
  
  begin
    # Do processing...
    rubric.update(status: :complete)
  rescue => e
    rubric.update(status: :failed)
  ensure
    # Always broadcast the final status
    Rubric::BroadcasterService.broadcast(rubric)
  end
end
```

## Views/Templates

To receive these broadcasts, views must subscribe to the rubric's channel:

```erb
<%= turbo_stream_from "rubric_#{@rubric.id}" %>

<div id="rubric_container_<%= @rubric.id %>">
  <%= render "grading_tasks/rubric_card", rubric: @rubric %>
</div>

<div id="rubric_status_badge_<%= @rubric.id %>">
  <%= render "shared/status_badge", status: @rubric.status, size: "sm" %>
</div>
```

## Best Practices

1. **Always reload** the rubric before broadcasting to ensure the most current state is shown
2. **Error handling** is important - broadcasts should not crash the application
3. **DOM IDs** must match exactly between the broadcaster and views
4. Use this service from background jobs, not controllers, to avoid blocking the request cycle
5. For complex UI updates, consider breaking updates into smaller, targeted broadcasts

## Integration with Status Changes

The broadcaster service pairs naturally with the status transition methods:

```ruby
# Example integration with status management
def mark_as_complete(rubric)
  Rubric::StatusManagerService.transition_to_complete(rubric)
  Rubric::BroadcasterService.broadcast(rubric)
end
```
