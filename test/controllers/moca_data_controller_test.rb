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
    # File.open("./test/fixtures/files/sample.pdf", "rb") do |file|
    #   f = Base64.encode64(file.read)
    # end
    
    # 指定のパスに遷移する
    assert_response :redirect
  end
end
