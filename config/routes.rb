Rails.application.routes.draw do
  resources :subject_data
  get '/result', to: 'subject_data#result'
end