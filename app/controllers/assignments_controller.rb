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
    # Use the strong params method to get permitted document data
    document_data = selected_documents_params.map { |p| p.to_h.symbolize_keys }

    # Prepare service input
    service_input = Assignment::InitializerService::Input.new(
      current_user: Current.user,
      assignment_params: assignment_params, # Use permitted params
      document_data: document_data
    )

    # Instantiate and call the service
    service = Assignment::InitializerService.new(input: service_input)
    result_assignment = service.call

    if result_assignment
      redirect_to result_assignment, notice: "Assignment was successfully created."
    else
      # Rebuild the assignment object with submitted params for form redisplay
      @assignment = Current.user.assignments.build(assignment_params)
      # Add a generic error message if the service failed
      # (A more specific error could be passed back from the service if needed)
      @assignment.errors.add(:base, "Assignment could not be created. Please check the details and selected documents.")

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

  # Define proper assignment_params using params.permit
  def assignment_params
    params.require(:assignment).permit(
      :title,
      :subject,
      :grade_level,
      :description,
      :instructions,
      :feedback_tone,
      :raw_rubric_text
    )
  end

  def rubric_params
    params.require(:assignment).permit(
      :rubric_option,
      :raw_rubric_text
    )
  end

  def selected_documents_params
    raw_data = params.require(:assignment).fetch(:document_data, "[]")

    parsed_data = begin
      JSON.parse(raw_data)
    rescue JSON::ParserError
      Rails.logger.error("Failed to parse document_data JSON: #{raw_data}")
      []
    end

    unless parsed_data.is_a?(Array)
      Rails.logger.warn("Parsed document_data is not an array: #{parsed_data.inspect}")
      return []
    end

    # Transform and permit keys for each hash in the parsed array
    parsed_data.map do |doc_hash|
      unless doc_hash.is_a?(Hash)
        Rails.logger.warn("Skipping non-hash element in document_data: #{doc_hash.inspect}")
        next nil # Skip if element is not a hash
      end

      # Transform keys and convert to symbols for the service
      transformed_hash = {
        google_doc_id: doc_hash["id"],
        title: doc_hash["name"], # Transform 'name' to 'title'
        url: doc_hash["url"]
      }

      # Select only the expected keys (already done by transformation)
      # No explicit permit needed here as we constructed the hash manually
      transformed_hash
    end.compact # Remove any nil elements resulting from non-hash items
  end
end
