# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users
  resources :moca_data, only: [:index]
  post '/moca_data', to: 'moca_data#upload'
  get '/moca_result', to: 'moca_data#result'
  # resources :compare
  # get '/compare_result', to: 'compare#result'
end