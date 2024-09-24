# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users
  resources :compare
  get '/moca_result', to: 'moca_data#result'
  # get '/compare_result', to: 'compare#result'
  resources :moca_data
end
