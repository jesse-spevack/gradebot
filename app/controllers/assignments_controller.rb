class AssignmentsController < ApplicationController
  # Ensures user is logged in (from ApplicationController -> Authentication concern)
  # before_action :require_authentication is implicitly included

  before_action :set_assignment, only: [ :show, :destroy ]

  # GET /assignments
  def index
    @assignments = Current.user.assignments.order(created_at: :desc)
  end

  # GET /assignments/new
  def new
    @assignment = Current.user.assignments.build
  end

  # POST /assignments
  def create
    @assignment = Assignment::InitializerService.call(input: initializer_service_input)

    if @assignment
      redirect_to @assignment, notice: "Assignment was successfully created."
    else
      @assignment = Current.user.assignments.build(initializer_service_input.to_assignment_params)
      render :new, status: :unprocessable_entity
    end
  end

  # GET /assignments/:id
  def show
    # @assignment is set by before_action :set_assignment
  end

  # DELETE /assignments/:id
  def destroy
    # @assignment is set by before_action :set_assignment
    # Authorization is handled by set_assignment finding only current_user's assignments
    if @assignment.destroy
      redirect_to assignments_url, notice: "Assignment was successfully destroyed."
    else
      # Handle potential destroy failure (e.g., callbacks aborting)
      redirect_to assignments_url, alert: "Assignment could not be destroyed."
    end
  end

  private

  def set_assignment
    @assignment = Current.user.assignments.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to assignments_url, alert: "Assignment not found."
  end

  # Define proper assignment_params using params.permit, only including Assignment attributes
  def assignment_params
    params.require(:assignment).permit(
      :title,
      :subject,
      :grade_level,
      :description,
      :instructions,
      :feedback_tone,
      :raw_rubric_text,
      :document_data
    )
  end

  def document_data
    JSON.parse(params.require(:assignment).fetch(:document_data))
  rescue JSON::ParserError => e
    Rails.logger.error("Failed to parse document_data: #{e.message}")
    []
  end

  def initializer_service_input
    Assignment::InitializerServiceInput.new(
      current_user: Current.user,
      assignment_params: assignment_params,
      document_data: document_data
    )
  end
end
