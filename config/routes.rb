# frozen_string_literal: true

Rails.application.routes.draw do
  resources :moca_data
  get '/moca_result', to: 'moca_data#result'
end
