# frozen_string_literal: true

# Pin npm packages by running ./bin/importmap

pin 'application'
pin '@hotwired/turbo-rails', to: 'turbo.min.js'
pin_all_from 'app/javascript/controllers', under: 'controllers'

pin 'result', to: 'result.js'
