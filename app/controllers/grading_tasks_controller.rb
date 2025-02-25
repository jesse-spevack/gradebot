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
      redirect_to grading_tasks_path, notice: "Grading task was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @grading_task = Current.session.user.grading_tasks.find(params[:id])
  end

  def destroy
    @grading_task = Current.session.user.grading_tasks.find(params[:id])
    @grading_task.destroy
    redirect_to grading_tasks_path, notice: "Grading task was successfully deleted."
  end

  private

  def grading_task_params
    params.require(:grading_task).permit(:assignment_prompt, :grading_rubric, :folder_id, :folder_name)
  end
end
