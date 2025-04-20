def toggle_rubric_status(rubric)
  status = rubric.status
  puts "Current status: #{status}"
  new_status = status == "pending" ? "complete" : "pending"
  rubric.update_column(:status, new_status)
  puts "Done"
end

begin
  Turbo::StreamsChannel.broadcast_update_to("rubric_#{rubric.id}", target: "rubric_container_#{rubric.id}", partial: "grading_tasks/rubric_card", locals: { rubric: rubric.reload })
rescue => error
  puts error.backtrace
  puts "Error: #{error}"
end
