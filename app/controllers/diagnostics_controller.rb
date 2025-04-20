# frozen_string_literal: true

# Controller for diagnostic and testing pages
class DiagnosticsController < ApplicationController
  # Skip auth for diagnostic pages - they're for testing only
  # skip_before_action :authenticate!, only: [ :test_rubric_stream, :update_rubric_status ]

  # before_action :authenticate_user!
  # before_action :ensure_admin, except: [ :test_rubric_stream, :update_rubric_status ]

  # Simple page for testing Turbo Stream updates to rubrics
  # @param id [Integer] The ID of the rubric to display and monitor
  def test_rubric_stream
    @rubric = Rubric.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:error] = "Rubric not found with ID: #{params[:id]}"
    redirect_to root_path
  end

  def rubric
    @rubric = Rubric.find(params[:id])
  end

  # Test any Turbo Stream channel by name
  # @param channel [String] The name of the channel to test
  def test_stream
    @channel = params[:channel] || "test_channel"
    @id = params[:id] || SecureRandom.hex(4)
    @full_channel = @channel.include?("_") ? @channel : "#{@channel}_#{@id}"
  end

  # Action to update rubric status and broadcast using custom template
  # @param id [Integer] The ID of the rubric to update
  # @param status [String] The new status (pending, processing, complete, failed)
  def update_rubric_status
    @rubric = Rubric.find(params[:id])

    # Get status from JSON body if present, otherwise from params
    status_param = if request.content_type =~ /json/
      params[:status] || (JSON.parse(request.body.read) rescue {})["status"]
    else
      params[:status]
    end

    status = status_param.presence || "pending"
    Rails.logger.info "⏩ Updating rubric #{@rubric.id} to status: #{status}"

    if @rubric.update_column(:status, status)
      # Use our custom template for the broadcast
      result = Rubric::BroadcasterService.new(@rubric.reload).broadcast("rubrics/update_status")
      Rails.logger.info "✅ Status updated and broadcast result: #{result.inspect}"

      respond_to do |format|
        format.html { redirect_to test_rubric_stream_path(@rubric), notice: "Status updated to #{@rubric.status}" }
        format.json { render json: { success: true, status: @rubric.status, display_status: @rubric.display_status, broadcast_result: result } }
        format.all { render json: { success: true, status: @rubric.status, display_status: @rubric.display_status }, content_type: "application/json" }
      end
    else
      Rails.logger.error "❌ Failed to update rubric status"
      respond_to do |format|
        format.html { redirect_to test_rubric_stream_path(@rubric), alert: "Failed to update status" }
        format.json { render json: { success: false, error: "Failed to update status" }, status: 422 }
        format.all { render json: { success: false, error: "Failed to update status" }, status: 422, content_type: "application/json" }
      end
    end
  rescue ActiveRecord::RecordNotFound
    Rails.logger.error "❌ Rubric not found with ID: #{params[:id]}"
    respond_to do |format|
      format.html { redirect_to root_path, alert: "Rubric not found" }
      format.json { render json: { success: false, error: "Rubric not found" }, status: 404 }
      format.all { render json: { success: false, error: "Rubric not found" }, status: 404, content_type: "application/json" }
    end
  rescue => e
    Rails.logger.error "❌ Error in update_rubric_status: #{e.message}"
    respond_to do |format|
      format.html { redirect_to root_path, alert: "Error: #{e.message}" }
      format.json { render json: { success: false, error: e.message }, status: 500 }
      format.all { render json: { success: false, error: e.message }, status: 500, content_type: "application/json" }
    end
  end

  private

  def ensure_admin
    redirect_to root_path, alert: "Not authorized" unless current_user.admin?
  end
end
