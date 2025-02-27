# frozen_string_literal: true

module Admin
  class FeatureFlagsController < BaseController
    before_action :set_feature_flag, only: [ :show, :edit, :update, :destroy ]
    before_action :initialize_feature_flag_service

    def index
      @feature_flags = FeatureFlag.ordered_by_name
      @audit_logs = FeatureFlagAuditLog.recent.limit(10).includes(:feature_flag, :user)
    end

    def show
      @audit_logs = FeatureFlagAuditLog.by_flag(@feature_flag.id).recent.includes(:user).limit(20)
    end

    def new
      @feature_flag = FeatureFlag.new
    end

    def edit
    end

    def create
      @feature_flag = FeatureFlag.new(feature_flag_params)

      if @feature_flag.save
        # Create an audit log if the flag is enabled when created
        @feature_flag_service.set_enabled(@feature_flag.key, @feature_flag.enabled, Current.user) if @feature_flag.enabled?

        redirect_to admin_feature_flag_path(@feature_flag), notice: "Feature flag was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      # Get the flag enabled status before the update
      previous_enabled = @feature_flag.enabled?
      new_enabled = feature_flag_params[:enabled] == "1"

      if @feature_flag.update(feature_flag_params.except(:enabled))
        # Only update the enabled status through the service to ensure proper audit logging
        if previous_enabled != new_enabled
          if new_enabled
            @feature_flag_service.enable(@feature_flag.key, Current.user)
          else
            @feature_flag_service.disable(@feature_flag.key, Current.user)
          end
        end

        redirect_to admin_feature_flag_path(@feature_flag), notice: "Feature flag was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @feature_flag.destroy
      # Force refresh cache after deletion
      @feature_flag_service.refresh_all_cache

      redirect_to admin_feature_flags_path, notice: "Feature flag was successfully deleted."
    end

    private

    def set_feature_flag
      @feature_flag = FeatureFlag.find(params[:id])
    end

    def feature_flag_params
      params.require(:feature_flag).permit(:key, :name, :description, :enabled)
    end

    def initialize_feature_flag_service
      @feature_flag_service = FeatureFlagService.new
    end
  end
end
