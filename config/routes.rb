Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # All requests to /api/v1/* will be routed to the appropriate service
  match "/api/v1/*path", to: "api_proxy#forward_request", via: :all, format: false

  post "/login", to: "authentication#login"
  post "/refresh", to: "authentication#refresh"
end
