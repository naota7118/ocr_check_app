# frozen_string_literal: true

require 'test_helper'

class MocaDataControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get moca_data_url
    assert_response :success
  end
  
  test "should post index" do
    image = File.open("./test/fixtures/files/sample.pdf", "rb:ASCII-8BIT:UTF-8")
    post moca_data_url, params: image
    assert_response :success
  end
end
