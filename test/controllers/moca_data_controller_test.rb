# frozen_string_literal: true

require 'test_helper'
require 'base64'

class MocaDataControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get moca_data_url
    assert_response :success
  end
  
  f = ''
  test "should post index" do
    # PDFファイルをPOSTで送る

    post moca_data_url, params: { upload: file_fixture_upload('sample.pdf', 'application/pdf') }
    pdf = ''
    # File.open("./test/fixtures/files/sample.pdf", "rb") do |file|
    #   pdf = file.binread
    #   post moca_data_url, params: { upload: pdf}
    #   # f = Base64.encode64(file.read)
    # end

    # 違うURLに遷移する（Google認証画面に遷移）
    assert_response :redirect
  end
end
