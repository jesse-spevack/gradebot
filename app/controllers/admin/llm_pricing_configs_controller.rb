# frozen_string_literal: true

module Admin
  class LLMPricingConfigsController < BaseController
    before_action :set_llm_pricing_config, only: [ :show, :edit, :update, :destroy ]

    def index
      @llm_pricing_configs = LLMPricingConfig.ordered
    end

    def show
    end

    def new
      @llm_pricing_config = LLMPricingConfig.new
    end

    def edit
    end

    def create
      @llm_pricing_config = LLMPricingConfig.new(llm_pricing_config_params)

      if @llm_pricing_config.save
        # Clear cache to ensure new pricing is used immediately
        Rails.cache.delete("llm_pricing/#{@llm_pricing_config.llm_model_name}")

        redirect_to admin_llm_pricing_configs_path, notice: "LLM pricing configuration was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      if @llm_pricing_config.update(llm_pricing_config_params)
        # Clear cache to ensure updated pricing is used immediately
        Rails.cache.delete("llm_pricing/#{@llm_pricing_config.llm_model_name}")

        redirect_to admin_llm_pricing_configs_path, notice: "LLM pricing configuration was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      # Don't allow deletion of the default pricing config
      if @llm_pricing_config.llm_model_name == "default"
        redirect_to admin_llm_pricing_configs_path, alert: "Cannot delete the default pricing configuration."
        return
      end

      @llm_pricing_config.destroy
      # Clear cache to ensure removal is reflected immediately
      Rails.cache.delete("llm_pricing/#{@llm_pricing_config.llm_model_name}")

      redirect_to admin_llm_pricing_configs_path, notice: "LLM pricing configuration was successfully deleted."
    end

    private

    def set_llm_pricing_config
      @llm_pricing_config = LLMPricingConfig.find(params[:id])
    end

    def llm_pricing_config_params
      params.require(:llm_pricing_config).permit(
        :llm_model_name,
        :prompt_rate,
        :completion_rate,
        :description,
        :active
      )
    end
  end
end
