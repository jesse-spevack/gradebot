class HomeController < ApplicationController
  allow_unauthenticated_access

  def index
    @email_signup = EmailSignup.new
  end

  def create_signup
    @email_signup = EmailSignup.new(email_signup_params)
    if @email_signup.save
      flash[:notice] = "Thanks for signing up! We'll keep you posted."
      flash[:target_form] = params[:email_signup][:form_id]
      redirect_to root_path
    else
      render :index, status: :unprocessable_entity
    end
  end

  private

  def email_signup_params
    params.require(:email_signup).permit(:email, :form_id)
  end
end
