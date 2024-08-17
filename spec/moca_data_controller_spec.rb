# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MocaDataController, type: :controller do
  describe 'GET #index' do
    it 'returns a sucessful response' do
      get :index
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:index)
    end
  end
end
