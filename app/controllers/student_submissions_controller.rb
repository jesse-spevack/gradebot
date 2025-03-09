class StudentSubmissionsController < ApplicationController
  before_action :set_student_submission, only: [ :show, :retry ]

  def show
    @grading_task = @student_submission.grading_task

    # Ensure the current user owns this submission via the grading task
    unless @grading_task.user == Current.session.user
      redirect_to root_path, alert: "You don't have permission to view this submission."
      nil
    end
  end

  def retry
    @grading_task = @student_submission.grading_task

    # Ensure the current user owns this submission via the grading task
    unless @grading_task.user == Current.session.user
      redirect_to root_path, alert: "You don't have permission to retry this submission."
      return
    end

    # Only allow retrying failed submissions
    unless @student_submission.failed?
      redirect_to student_submission_path(@student_submission), alert: "Only failed submissions can be retried."
      return
    end

    # Use StatusManager to retry the submission
    if StatusManager.retry_submission(@student_submission)
      # Requeue the submission for processing
      StudentSubmissionJob.perform_later(@student_submission.id)

      redirect_to student_submission_path(@student_submission), notice: "Submission has been queued for reprocessing."
    else
      redirect_to student_submission_path(@student_submission), alert: "Failed to retry submission. Please try again."
    end
  end

  def update
    @student_submission = StudentSubmission.find(params[:id])
    @grading_task = @student_submission.grading_task

    # Ensure the current user owns this submission via the grading task
    unless @grading_task.user == Current.session.user
      redirect_to root_path, alert: "You don't have permission to view this submission."
      return
    end

    # This action just renders the update.turbo_stream.erb template
    # which updates all relevant elements
    respond_to do |format|
      format.turbo_stream
    end
  end

  private

  def set_student_submission
    @student_submission = StudentSubmission.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Submission not found."
  end
end
