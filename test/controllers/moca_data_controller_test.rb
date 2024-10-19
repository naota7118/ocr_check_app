# frozen_string_literal: true

require 'test_helper'
require 'base64'

class MocaDataControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get moca_data_url
    assert_response :success
  end
  
  test "should post index" do
    # PDFファイルをPOSTリクエストで送る
    post moca_data_url, params: { upload: file_fixture_upload('sample.pdf', 'application/pdf') }

    # 違うURLに遷移する（Google認証画面に遷移）
    assert_response :redirect
  end

end
