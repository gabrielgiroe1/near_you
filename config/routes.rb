Rails.application.routes.draw do
  get "favorites/create"
  get "favorites/destroy"
  mount MissionControl::Jobs::Engine, at: "/jobs"

  get "up", to: "rails/health#show", as: :rails_health_check

  authenticate :user, lambda { |u| u.admin? } do
    mount Avo::Engine, at: Avo.configuration.root_path
  end

  devise_for :users, controllers: { registrations: "users/registrations" }

  root "providers#index"

  get :favorites, to: "favorites#index", as: :favorites
  resources :providers, only: [:index, :show, :new, :create, :edit, :update] do
    post :favorite, to: "favorites#create", as: :favorite
    delete :unfavorite, to: "favorites#destroy", as: :unfavorite
    collection do
      get :service_types
      get :search_suggestions
    end
    resources :availabilities, only: [:index, :create, :update, :destroy]
    get "available_slots", on: :member
    resources :appointments, only: [:create]
    resources :reviews, only: [:create, :update, :destroy] do
      resources :review_responses, only: [:create, :update, :destroy]
    end

    # Custom routes for image management
    member do
      delete "purge_image", to: "providers#purge_image", as: :purge_image
    end
  end

  resources :appointments, only: [:index] do
    get :success, on: :member
    get :cancel, on: :member
  end

  post "/stripe/webhook", to: "stripe#webhook"
  resources :stripe_connect, only: [:create] do
    collection do
      get :refresh
    end
  end

  resources :notifications, only: [] do
    member do
      patch :read
    end
  end
end
