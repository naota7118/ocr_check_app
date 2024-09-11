# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  user = User.new(id: 1, email: 'aaa@email.com', password: 'password')

  it 'メールアドレスが空だと無効になる' do
    expect(user.email = nil).not_to eq be_valid
  end
end
