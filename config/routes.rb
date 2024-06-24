# frozen_string_literal: true

Rails.application.routes.draw do
  resources :subject_data
  resources :moca_data
  get '/result', to: 'subject_data#result'
  get '/moca_result', to: 'moca_data#result'
end