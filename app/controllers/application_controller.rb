class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  include Authentication

  private

  def flash_for_turbo_stream(type, message)
    turbo_stream.update "flash" do
      render partial: "shared/flash", locals: { flash: { type => message } }
    end
  end
end
