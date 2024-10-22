# frozen_string_literal: true

require 'test_helper'
require 'base64'

class TestScoresControllerTest < ActionDispatch::IntegrationTest

  test "should get index" do
    get test_scores_path
    assert_response :success
  end
  
  test "should post index and file upload" do
    # フォームからPDFを送る
    post test_scores_path, params: { upload: file_fixture_upload('sample.pdf', 'application/pdf') }

    # Googleアカウント選択画面に遷移する
    assert_redirected_to "http://www.example.com/test_scores_result", params: {
      access_type: "online",
      client_id: ENV['GOOGLE_CLIENT_ID'],
      include_granted_scopes: true,
      redirect_uri: "http://localhost:3000/test_scores_result",
      response_type: "code",
      scope: "https://www.googleapis.com/auth/drive"
    }
  end

end
