class SessionsController < ApplicationController
  allow_unauthenticated_access only: [ :new, :create ]

  def new
  end

  def create
    if auth = request.env["omniauth.auth"]
      user = User.from_google_auth(auth)
      session = start_new_session_for(user)
      session.update!(access_token: auth.credentials.token)
      redirect_to new_grading_task_path, notice: "Successfully signed in!"
    else
      redirect_to new_session_path, alert: "Authentication failed."
    end
  rescue StandardError => e
    redirect_to new_session_path, alert: "Authentication failed: #{e.message}"
  end

  def destroy
    terminate_session
    redirect_to root_path, notice: "Successfully signed out!"
  end
end
