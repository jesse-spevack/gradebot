#!/usr/bin/env ruby
# Simple script to test broadcasting rubric updates with a specific template
# Usage: rails runner scripts/test_turbo_broadcast.rb RUBRIC_ID [TEMPLATE]
#
# Examples:
#   rails runner scripts/test_turbo_broadcast.rb 31
#   rails runner scripts/test_turbo_broadcast.rb 31 rubrics/update_status

require 'fileutils'

# Configure logging to display in console
Rails.logger = Logger.new($stdout)
Rails.logger.level = Logger::INFO

# Process command line arguments
if ARGV.empty?
  puts "❌ Error: You must provide a rubric ID"
  puts "Usage: rails runner scripts/test_turbo_broadcast.rb RUBRIC_ID [TEMPLATE]"
  exit 1
end

rubric_id = ARGV[0]
template = ARGV[1] # Optional template path

puts "="*80
puts "🔄 TURBO STREAM BROADCAST TEST"
puts "="*80
puts "• Looking for rubric with ID: #{rubric_id}"
puts "• Template: #{template || 'using default'}"
puts

# Find the rubric
begin
  rubric = Rubric.find(rubric_id)
  puts "✅ Found rubric: #{rubric.title} (ID: #{rubric.id})"
  puts "• Current status: #{rubric.status}"
  puts "• Display status: #{rubric.display_status}"
  puts
rescue ActiveRecord::RecordNotFound
  puts "❌ Error: Rubric with ID #{rubric_id} not found"
  exit 1
end

# Cycle through all statuses
statuses = [ "pending", "processing", "complete", "failed" ]
current_index = statuses.index(rubric.status.to_s)
next_status = statuses[(current_index + 1) % statuses.length]

puts "🔄 Updating rubric status to: #{next_status}"
rubric.update_column(:status, next_status)
puts "✅ Status updated in database"
puts

puts "📡 Broadcasting with #{template ? "template: #{template}" : "default template"}"
puts "• Creating broadcaster service instance..."
broadcaster = Rubric::BroadcasterService.new(rubric.reload)
puts "• Calling broadcast method..."

# Direct method call with detailed output
if template
  puts "• Using template: #{template}"
  result = broadcaster.broadcast(template)
else
  puts "• Using default templates"
  result = broadcaster.broadcast
end

puts "• Broadcast result: #{result}"
puts

puts "📊 Verification Info:"
puts "• Updated rubric status: #{rubric.reload.status}"
puts "• DOM ID targets to check:"
puts "  - Container: #{broadcaster.send(:container_dom_id)}"
puts "  - Status badge: #{broadcaster.send(:status_badge_dom_id)}"
puts
puts "• View the grading task page to see if updates appear:"
puts "  http://localhost:3000/grading_tasks/#{rubric.grading_tasks.last.id}" if rubric.grading_tasks.present?
puts "• View the test page to confirm updates are working:"
puts "  http://localhost:3000/test-rubric-turbo-stream/#{rubric.id}"
puts
puts "="*80
puts "Done! Check browser console for broadcast events."
puts "="*80
