class DocumentActionsController < ApplicationController
  before_action :set_student_submission
  before_action :verify_access_rights

  def create
    @document_action = @student_submission.document_actions.new(
      document_action_params
    )

    if @document_action.save
      respond_to do |format|
        format.html { redirect_to student_submission_path(@student_submission), notice: "Posting feedback..." }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("document_action_section_#{@student_submission.id}", partial: "document_actions/section", locals: { document_action: @document_action }) }
      end
    else
      respond_to do |format|
        format.html { redirect_to student_submission_path(@student_submission), alert: "Failed to post feedback: #{@document_action.errors.full_messages.join(', ')}" }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("flash", partial: "shared/flash", locals: { flash: { alert: "Failed to post feedback: #{@document_action.errors.full_messages.join(', ')}" } }) }
      end
    end
  end

  private

  def document_action_params
    params.expect(document_action: [ :action_type ])
  end

  def set_student_submission
    @student_submission = StudentSubmission.find(params[:student_submission_id])
  end

  def verify_access_rights
    unless @student_submission.grading_task.user == Current.session.user
      redirect_to root_path, alert: "You don't have permission to perform this action."
    end
  end
end
