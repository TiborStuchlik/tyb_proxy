Rails.application.routes.draw do
  namespace :tyb do
    resources :configurations
    resources :redirects
    resources :cas
    resources :certificates do
      get 'new_key', on: :member
      get 'new_certificate', on: :member
      get 'download', on: :member
      get 'clear', on: :member
      get 'check', on: :collection
    end
    resources :logs do
      get 'clear', on: :collection
    end
  end

  resources :redirects do
    resource :certificate, controller: :certificate
  end
  resources :cas

  #get "certificates/*id", to: "certificates#show", format: false

  get "command/(*command)", to: "command#command"
  post "command/(*command)", to: "command#command"

  match "(*path)" => "application#index", via: [:get, :post, :put, :patch, :delete]
  root "application#index"

end
