Rails.application.routes.draw do
  get "features/index"
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
      get :google_drive_auth_test
      post :google_drive_auth_test
    end
  end

  # Admin routes
  namespace :admin do
    resources :features
    resources :feature_flags

    # Reports namespace
    namespace :reports do
      get "daily", to: "daily#show"
      get "grading_tasks", to: "grading_tasks#show"
    end

    resources :llm_pricing_configs

    # Job monitoring
    resources :job_monitoring, only: [ :index ]
  end

  # Application routes
  root "home#index"
  get "/privacy", to: "pages#privacy", as: :privacy
  get "/terms", to: "pages#terms", as: :terms

  resources :grading_tasks, only: [ :new, :create, :index, :show, :destroy ]
  resources :student_submissions, only: [ :show, :update ] do
    resources :document_actions, only: [ :create ]
  end
  resources :features, only: [ :index ]

  # Diagnostic route for Turbo Stream testing
  get "/test-rubric-turbo-stream/:id", to: "diagnostics#test_rubric_stream", as: :test_rubric_stream
  get "/diagnostics/rubric/:id", to: "diagnostics#rubric", as: :diagnostic_rubric
  post "/diagnostics/update-rubric-status/:id", to: "diagnostics#update_rubric_status", as: :update_rubric_status
  get "/test-stream/:channel/:id", to: "diagnostics#test_stream", as: :test_stream
  get "/test-stream", to: "diagnostics#test_stream"
end
