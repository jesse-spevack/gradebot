class GradingTasksController < ApplicationController
  # Temporary data structure for UI development
  TemporaryGradingTaskData = Struct.new(
    :id, :name, :status, :course, :grade_level, :due_date,
    :student_count, :graded_count, :time_info, :last_edited_at,
    keyword_init: true
  )

  def index
    @grading_tasks = Current.session.user.grading_tasks.order(created_at: :desc)

    @temporary_grading_tasks = [
      TemporaryGradingTaskData.new(
        id: 1,
        name: "Essay Analysis: Impact of Climate Change",
        status: "in_progress",
        course: "Environmental Science",
        grade_level: "11",
        due_date: Date.new(2025, 4, 15),
        student_count: 28,
        graded_count: 18,
        time_info: "~20 min remaining"
      ),
      TemporaryGradingTaskData.new(
        id: 2,
        name: "Lab Report: Chemical Reactions",
        status: "complete",
        course: "Science",
        grade_level: "11",
        due_date: Date.new(2025, 3, 10),
        student_count: 26,
        graded_count: 26,
        time_info: "Completed Mar 12"
      ),
      TemporaryGradingTaskData.new(
        id: 3,
        name: "Research Project: Renewable Energy",
        status: "in_progress",
        course: "Environmental Science",
        grade_level: "11",
        due_date: Date.new(2025, 4, 8),
        student_count: 25,
        graded_count: 11,
        time_info: "~35 min remaining"
      ),
      TemporaryGradingTaskData.new(
        id: 4,
        name: "Midterm Exam: Ecology",
        status: "complete",
        course: "Science",
        grade_level: "11",
        due_date: Date.new(2025, 3, 20),
        student_count: 28,
        graded_count: 28,
        time_info: "Completed Mar 23"
      ),
      TemporaryGradingTaskData.new(
        id: 5,
        name: "Final Project: Climate Solutions",
        status: "draft",
        course: "Environmental Science",
        grade_level: "11",
        due_date: nil,
        student_count: nil,
        graded_count: nil,
        time_info: nil,
        last_edited_at: Date.new(2025, 4, 1)
      )
    ]
  end

  def new
    @grading_task = GradingTask.new
    @grading_task.build_assignment_prompt
  end

  def create
    kick_off_request = GradingTaskKickOffRequest.from_controller_params(
      grading_task_params,
      Current.session.user,
      json_document_data_params
    )

    if kick_off_request.valid?
      @grading_task = GradingTask::KickOffService.call(kick_off_request)

      @document_selections = DocumentSelection::BulkCreationService.call(
        grading_task: @grading_task,
        document_data: kick_off_request.document_data
      )

      student_submissions = StudentSubmission::BulkCreationService.call(
        grading_task: @grading_task,
        document_selections: @document_selections
      )

      Rails.logger.info("Enqueueing grading task job for grading task #{@grading_task.id}")
      GradingTaskJob.perform_later(@grading_task.id)

      redirect_to grading_task_path(@grading_task), notice: "Grading task was successfully created with #{student_submissions.length} pieces of student work."
    else
      @grading_task = GradingTask.new(grading_task_params)
      @grading_task.build_assignment_prompt if @grading_task.assignment_prompt.nil?
      flash.now[:alert] = "Could not create grading task: #{kick_off_request.errors.full_messages.join(', ')}"
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @grading_task = GradingTask.find(params[:id])
    @student_submissions = @grading_task.student_submissions.oldest_first

    # Ensure the current user owns this grading task
    unless @grading_task.user == Current.session.user
      redirect_to root_path, alert: "You don't have permission to view this grading task."
      nil
    end
  end

  def destroy
    @grading_task = Current.session.user.grading_tasks.find(params[:id])
    @grading_task.destroy
    redirect_to grading_tasks_path, notice: "Grading task was successfully deleted."
  end

  private

  def grading_task_params
    params.require(:grading_task).permit(
      :rubric_raw_text, :ai_generate_rubric, :feedback_tone, :document_data,
      assignment_prompt_attributes: [
        :id, :title, :content, :word_count, :grade_level, :subject, :due_date
      ]
    )
  end

  def json_document_data_params
    return [] if params[:grading_task][:document_data].blank?

    DocumentDataCollection.from_json(params[:grading_task][:document_data])
  end
end
