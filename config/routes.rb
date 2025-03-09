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

  # Admin routes
  namespace :admin do
    resources :feature_flags
    resources :llm_cost_reports, only: [ :index ] do
      collection do
        get :user_costs
      end
    end
    resources :llm_pricing_configs
  end

  # Application routes
  root "home#index"
  post "/signup", to: "home#create_signup", as: :email_signups
  resources :grading_tasks, only: [ :new, :create, :index, :show, :destroy ]
  resources :student_submissions, only: [ :show, :update ] do
    member do
      post :retry
    end
  end
  get "/privacy", to: "pages#privacy", as: :privacy
  get "/terms", to: "pages#terms", as: :terms
end
