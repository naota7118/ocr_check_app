# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users
  resources :test_scores, only: [:index, :create]
  get '/test_scores_result', to: 'test_scores#result'
end