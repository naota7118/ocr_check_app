# frozen_string_literal: true

require 'test_helper'
require 'base64'

class TestScoresControllerTest < ActionDispatch::IntegrationTest

  test "should get index" do
    get test_scores_path
    assert_response :success
  end
  
  test "should post index and file upload" do
    post test_scores_path, params: { upload: file_fixture_upload('sample.pdf', 'application/pdf') }
    assert_response :redirect
  end

  # 
  test "should get result" do
    get test_scores_result_path
    assert_response :success
  end

end
