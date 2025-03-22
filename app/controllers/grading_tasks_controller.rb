class GradingTasksController < ApplicationController
  def index
    @grading_tasks = Current.session.user.grading_tasks.order(created_at: :desc)
  end

  def new
    @grading_task = GradingTask.new
  end

  def create
    @grading_task = Current.session.user.grading_tasks.build(grading_task_params)

    if @grading_task.save
      create_document_selection_command = CreateDocumentSelectionCommand.call(
        document_data: document_data_params,
        grading_task: @grading_task
      )

      render :new, status: :unprocessable_entity if create_document_selection_command.failure?

      document_selections = create_document_selection_command.result
      create_student_submission_command = CreateStudentSubmissionsCommand.new(
        grading_task: @grading_task,
        document_selections: document_selections
      )

      create_student_submission_command.call

      redirect_to grading_task_path(@grading_task), notice: "Grading task was successfully created with #{document_selections.length} pieces of student work."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @grading_task = GradingTask.find(params[:id])

    # Ensure the current user owns this grading task
    unless @grading_task.user == Current.session.user
      redirect_to root_path, alert: "You don't have permission to view this grading task."
      return
    end

    # Reload to ensure we have the latest data
    @grading_task.reload

    # Get a fresh count of submissions directly from the database
    @student_submissions = @grading_task.student_submissions.reload.oldest_first

    # Ensure submission counts are fresh by running the status manager count
    @submission_counts = StatusManager.count_submissions_by_status(@grading_task)

    # Calculate the progress percentage
    @progress_percentage = StatusManager.calculate_progress_percentage(@grading_task)

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def destroy
    @grading_task = Current.session.user.grading_tasks.find(params[:id])
    @grading_task.destroy
    redirect_to grading_tasks_path, notice: "Grading task was successfully deleted."
  end

  private

  def grading_task_params
    params.expect(grading_task: [ :assignment_prompt, :grading_rubric ])
  end

  def document_data_params
    document_data_params = params.expect(grading_task: [ :document_data ])
    JSON.parse(document_data_params[:document_data])
  end
end
