# frozen_string_literal: true

module Admin
  class BaseController < ApplicationController
    before_action :require_admin

    private

    def require_admin
      unless Current.user&.admin?
        flash[:alert] = "You do not have permission to access that page."
        redirect_to root_path
      end
    end
  end
end
