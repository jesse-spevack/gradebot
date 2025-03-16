#!/usr/bin/env ruby
# Run this script with: bin/rails runner test/scripts/test_status_label.rb

# Get a grading task
grading_task = GradingTask.first

puts "Initial status: #{grading_task.status}"
puts "Initial status label: #{grading_task.status_label}"

# Test each status
statuses = %w[
  created
  assignment_processing
  assignment_processed
  rubric_processing
  rubric_processed
  submissions_processing
  completed
  completed_with_errors
  failed
]

statuses.each do |status|
  puts "\nSetting status to: #{status}"
  grading_task.update_column(:status, status)
  grading_task.reload
  puts "Status: #{grading_task.status}"
  puts "Status label: #{grading_task.status_label}"
end

# Reset to original status
puts "\nResetting to original status"
grading_task.update_column(:status, "completed")
grading_task.reload
puts "Final status: #{grading_task.status}"
puts "Final status label: #{grading_task.status_label}"
