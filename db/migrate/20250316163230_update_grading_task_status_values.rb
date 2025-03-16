class UpdateGradingTaskStatusValues < ActiveRecord::Migration[8.0]
  def up
    # Map old status values to new ones
    GradingTask.where(status: 0).update_all(status: :created) # pending -> created
    GradingTask.where(status: 1).update_all(status: :submissions_processing) # processing -> submissions_processing
    GradingTask.where(status: 2).update_all(status: :completed) # completed -> completed
    GradingTask.where(status: 3).update_all(status: :failed) # completed_with_errors -> failed
  end

  def down
    # Map new status values back to old ones
    GradingTask.where(status: :created).update_all(status: 0) # created -> pending
    GradingTask.where(status: :assignment_processing).update_all(status: 1) # assignment_processing -> processing
    GradingTask.where(status: :assignment_processed).update_all(status: 1) # assignment_processed -> processing
    GradingTask.where(status: :rubric_processing).update_all(status: 1) # rubric_processing -> processing
    GradingTask.where(status: :rubric_processed).update_all(status: 1) # rubric_processed -> processing
    GradingTask.where(status: :submissions_processing).update_all(status: 1) # submissions_processing -> processing
    GradingTask.where(status: :completed).update_all(status: 2) # completed -> completed
    GradingTask.where(status: :failed).update_all(status: 3) # failed -> completed_with_errors
  end
end
