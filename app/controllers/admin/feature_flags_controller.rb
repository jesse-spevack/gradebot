# frozen_string_literal: true

module Admin
  class FeatureFlagsController < BaseController
    before_action :set_feature_flag, only: [ :show, :edit, :update, :destroy ]

    def index
      @feature_flags = FeatureFlag.ordered_by_name
    end

    def show
    end

    def new
      @feature_flag = FeatureFlag.new
    end

    def edit
    end

    def create
      @feature_flag = FeatureFlag.new(feature_flag_params)

      if @feature_flag.save
        redirect_to admin_feature_flag_path(@feature_flag), notice: "Feature flag was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      if @feature_flag.update(feature_flag_params)
        redirect_to admin_feature_flag_path(@feature_flag), notice: "Feature flag was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @feature_flag.destroy
      redirect_to admin_feature_flags_path, notice: "Feature flag was successfully deleted."
    end

    private

    def set_feature_flag
      @feature_flag = FeatureFlag.find(params[:id])
    end

    def feature_flag_params
      params.expect(:feature_flag).permit(:key, :name, :description, :enabled)
    end
  end
end
