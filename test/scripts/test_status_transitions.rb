#!/usr/bin/env ruby
# Run this script with: bin/rails runner test/scripts/test_status_transitions.rb

# Get a grading task
grading_task = GradingTask.first

puts "Initial status: #{grading_task.status}"
puts "Initial status label: #{grading_task.status_label}"

# Reset to created status
puts "\nResetting to created status"
grading_task.update_column(:status, "created")
grading_task.reload
puts "Status: #{grading_task.status}"
puts "Status label: #{grading_task.status_label}"

# Simulate the state transitions
puts "\nSimulating state transitions"

puts "\nStarting assignment processing"
grading_task.start_assignment_processing!
grading_task.reload
puts "Status: #{grading_task.status}"
puts "Status label: #{grading_task.status_label}"

puts "\nCompleting assignment processing"
grading_task.complete_assignment_processing!
grading_task.reload
puts "Status: #{grading_task.status}"
puts "Status label: #{grading_task.status_label}"

puts "\nCompleting rubric processing"
grading_task.complete_rubric_processing!
grading_task.reload
puts "Status: #{grading_task.status}"
puts "Status label: #{grading_task.status_label}"

puts "\nCompleting processing"
grading_task.complete_processing!
grading_task.reload
puts "Status: #{grading_task.status}"
puts "Status label: #{grading_task.status_label}"

# Reset to original status
puts "\nResetting to original status"
grading_task.update_column(:status, "completed")
grading_task.reload
puts "Final status: #{grading_task.status}"
puts "Final status label: #{grading_task.status_label}"
