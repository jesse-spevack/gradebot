Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Authentication routes
  resource :session, only: [ :new, :create, :destroy ]
  get "/auth/:provider/callback", to: "sessions#create"
  get "/auth/failure", to: redirect("/")

  # Google Drive routes
  resources :google_drive, only: [] do
    collection do
      get :credentials
      get :folder_contents
    end
  end

  # Application routes
  root "home#index"
  post "/signup", to: "home#create_signup", as: :email_signups
  get "/grading-job", to: "grading_jobs#index", as: :grading_job
  get "/privacy", to: "pages#privacy", as: :privacy
  get "/terms", to: "pages#terms", as: :terms
end
