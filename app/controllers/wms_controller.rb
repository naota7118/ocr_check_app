# frozen_string_literal: true

require 'google/apis/drive_v3'
require 'google/api_client/client_secrets'
require 'roo'
require 'rubyXL'
require 'rubyXL/convenience_methods'
require 'pdf/reader'

class WmsController < ApplicationController
  # ファイルアップロード用のビューを返す
  def index; end

  # フォームで送られたPDFファイルを格納しresult関数を呼び出す
  def create
    uploaded_file = params[:upload]
    if uploaded_file
      file_path = Rails.root.join("public/uploads/#{uploaded_file.original_filename}")
      File.binwrite(file_path, uploaded_file.read)
      redirect_to wms_result_path
    end
  end

  class PDFConverter
    def convert_into_text(drive)
      file_path = Dir.glob(Rails.root.join('public/uploads/*.pdf').to_s)
      metadata = Google::Apis::DriveV3::File.new(name: file_path[0])
      @metadata = drive.create_file(metadata, upload_source: file_path[0], content_type: '/pdf')
      # Googleドキュメント形式に変換
      @google_document = drive.copy_file(@metadata.id, Google::Apis::DriveV3::File.new(mime_type: 'application/vnd.google-apps.document'))
      # テキストファイルを出力
      drive.export_file(@google_document.id, 'text/plain', download_dest: './tmp/txt/wms.txt')
    end

    def remove_pdf_from_drive(drive)
      drive.delete_file(@metadata.id)
    end

    def remove_document_from_drive(drive)
      drive.delete_file(@google_document.id)
    end
  end

  # 検査データオブジェクトをつくるクラス
  class WMSTest
    attr_accessor :raw_data, :scores_and_title
    def initialize
      text_per_line_in_array = []
      File.open('./tmp/txt/wms.txt', 'r') do |f|
        f.each_line do |line|
          text_per_line_in_array << line.strip
        end
      end
      @raw_data = text_per_line_in_array
    end

    def scores_and_title(data)
      data.map! do |line|
        if line.match?(/^[0-6]$|^[1-5][0-9]$|論理的記憶/)
          line
        end
      end
      @scores_and_title = data.compact!
    end
  end

  # 得点データのみに変換（文字列「論理的記憶」のみ例外）
  class ScoreTitleExtracter
    attr_accessor :only_scores_and_title
    def extract_scores_and_title(data)
      # 「論理的記憶」はPDFごとに区切るのに必要
      @only_scores_and_title = data.map! do |line|
        if line.match?(/^[0-6]$|^[1-5][0-9]$|論理的記憶/)
          @wms_scores << line
        end
      end
    end
  end

  # PDFとエクセルの得点データを照合し、結果を返す
  def result
    # Google認証
    pass_authentication
    return if performed?

    @pdf_converter = PDFConverter.new
    @pdf_converter.convert_into_text(@drive)
    @pdf_converter.remove_pdf_from_drive(@drive)
    @pdf_converter.remove_document_from_drive(@drive)

    @wms_test_data = WMSTest.new
    @raw_data = @wms_test_data.raw_data
    @scores_and_title = @wms_test_data.scores_and_title(@raw_data)
    
    # PDF1枚ごとに配列を分割
    separate_each_pdf(@wms_scores)
  end

  # Excelで行ごとに出力するため、PDF1枚ごとの配列に分割する
  def separate_each_pdf(wms_scores)
    @wms_scores = wms_scores.deep_dup
    @each_pdf_scores = @wms_scores.slice_before(/^[0-9]*[0-9]+\s論理的記憶/).to_a
  end

  private

  # Google API認証を通す
  def pass_authentication
    # client_secret.jsonファイルを読み取ってオブジェクトを作成
    client_secrets = Google::APIClient::ClientSecrets.load
    auth_client = client_secrets.to_authorization
    auth_client.update!(
      scope: 'https://www.googleapis.com/auth/drive',
      redirect_uri: Rails.application.credentials.dig(:google, :wms_redirect_uri),
      additional_parameters: {
        'access_type' => 'online',
        'response_type' => 'code',
        'prompt' => 'select_account'
      }
    )
    if request.params['code'].nil? # 認可コードを持っていない場合
      auth_uri = auth_client.authorization_uri.to_s
      redirect_to auth_uri, allow_other_host: true
    else # 認可コードを持っている場合
      auth_client.code = request.params['code']
      # 認可コードを使ってアクセストークンを取得
      auth_client.fetch_access_token!
      auth_client.client_secret = nil
      session[:credentials] = auth_client.to_json
      client_opts = JSON.parse(session[:credentials])
      auth_client = Signet::OAuth2::Client.new(client_opts)
      @drive = Google::Apis::DriveV3::DriveService.new.tap do |client|
        client.client_options.open_timeout_sec = 120
        client.client_options.read_timeout_sec = 120
        client.request_options.retries = 3
      end
      @drive.authorization = auth_client
    end
  end

end
