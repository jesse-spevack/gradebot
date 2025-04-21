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
    # TODO: Define expected params structure based on form submission (Task 15)
    # expected_params = params.expect(
    #   assignment: [
    #     :title, :subject, :grade_level, :instructions,
    #     :raw_rubric_text, :generate_rubric_flag, # Rubric options
    #     selected_documents: [[:id, :name, :url]] # Array of hashes from picker
    #   ]
    # )
    # assignment_attrs = expected_params[:assignment].except(:selected_documents, :generate_rubric_flag, :raw_rubric_text)
    # selected_docs_data = expected_params[:assignment][:selected_documents]
    # Handle rubric choice...

    # TEMPORARY: Use permit for basic fields until params.expect structure is known
    assignment_attrs = params.require(:assignment).permit(:title, :subject, :grade_level, :instructions, :raw_rubric_text)

    @assignment = Current.user.assignments.build(assignment_attrs)

    # TODO: Replace direct save with call to Assignment::InitializerService (Task 18)
    # which should handle Assignment creation, SelectedDocument creation, and Job enqueuing.

    if @assignment.save
      # TODO: Potentially kick off background job here if not using InitializerService yet
      redirect_to @assignment, notice: "Assignment was successfully created."
    else
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

  # TODO: Define proper assignment_params using params.expect when form structure is clear
  # def assignment_params
  #   ...
  # end
end
