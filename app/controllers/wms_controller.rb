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
    attr_accessor :raw_data, :wms_scores_and_title
    def initialize
      text_per_line_in_array = []
      File.open('./tmp/txt/wms.txt', 'r') do |f|
        f.each_line do |line|
          text_per_line_in_array << line.strip
        end
      end
      @raw_data = text_per_line_in_array
      FileUtils.rm_r(Dir.glob(Rails.root.join('tmp/txt/*.txt').to_s))
    end

    def scores_and_title(data)
      data.map! do |line|
        if line.match?(/^[0-6]$|^[1-5][0-9]$/)
          line
        elsif line.match?(/^[1-5][0-9]\./)
          line[0, 2]
        elsif line.match?(/論理的記憶/)
          line = '論理的記憶'
        end
      end
      @wms_scores_and_title = data.compact!
    end

  end

  class PageCountDeleter
    attr_accessor :wms_array
    def initialize(array)
      @wms_array = array
    end

    def delete(array)
      array.each_with_index do |_, i|
        if array[i] == '5' && array[i+1] == '物語B得点'
          array.delete_at(i)
        end
      end
      array
    end
  end

  class StrikeThroughChecker
    def initialize(array)
      @wms_array = array
    end
  
    # 取り消し線で修正された後の得点を取得
    def corrected_score(array)
      array.each_with_index do |_, i|
        if array[i].match?(/≠ [0-6]|≠[0-6]/)
          array[i] = array[i][-1, 1]
        end
      end
      array
    end
  end

  class FindSum
    def initialize(array)
      @wms_array = array
    end

    # 文字列の中に入っている得点を取得 例：粗点 (物語A+B) 32
    def sum_score(array)
      array.each_with_index do |_, i|
        if array[i].match?(/物語A\+B.*[0-5][0-9]/)
          array[i] = array[i][-2, 2]
        elsif array[i].match?(/最高.*:25.*[0-5][0-9]/)
          array[i] = array[i].scan(/[0-5][0-9]/)[1]
        elsif array[i].match?(/最高.*:25.*[0-9]/)
          array[i] = array[i].scan(/[0-9]/)[2]
        end
      end
      array
    end
  end

  def find_subject_id(array)
    subjects = array.deep_dup
    subjects.map! do |subject|
      if subject.match?(/Osaka/)
        subject = subject.match(/Osaka.*[0-9]/).to_s
      end
    end
    subjects.compact!
  end

  def shape(wms_array)
    wms_array.shift
    wms_array.partition.each_with_index { |_, index| index < 7 }
  end

  def pair(ids, scores)
    @wms_id_and_score = []
    ids.each_with_index do |id, i|
      one_person_data = {}
      one_person_data[:id] = id
      one_person_data[:scores] = scores[i]
      @wms_id_and_score << one_person_data
    end
    @wms_id_and_score
  end

  def alter_string_to_number(results)
    results.map! do |person|
      person.map! do |story|
        story.map! do |score|
          score.to_i
        end
      end
    end
  end

  # resultハッシュに格納する
  def sum_check(results)
    results.each_with_index do |result, i|
      # 1人分ずつ処理する
      # 問題A合計が間違っている
      if result[:scores][0][0..5].sum != result[:scores][0][6]
        results[i][:story_a_sum] = false
      end

      # 問題B合計が間違っている
      if result[:scores][1][0..6].sum != result[:scores][1][7]
        results[i][:story_b_sum] = false
      end

      # 問題A+B合計が間違っている
      if (result[:scores][0][6] + result[:scores][1][7]) != result[:scores][1][8]
        results[i][:wms_sum] = false
      end
    end
  end

  # PDFとエクセルの得点データを照合し、結果を返す
  def result
    # Google認証
    pass_authentication
    return if performed?

    pdf_converter = PDFConverter.new
    pdf_converter.convert_into_text(@drive)
    pdf_converter.remove_pdf_from_drive(@drive)
    pdf_converter.remove_document_from_drive(@drive)

    FileUtils.rm_r(Dir.glob(Rails.root.join('public/uploads/*.pdf').to_s))

    wms_test = WMSTest.new
    @raw_data = wms_test.raw_data

    @subjects = find_subject_id(@raw_data)

    page_count_deleter = PageCountDeleter.new(@raw_data)
    @wms_array = page_count_deleter.wms_array
    @wms_array = page_count_deleter.delete(@wms_array)

    strike_through_checker = StrikeThroughChecker.new(@wms_array)
    @wms_array = strike_through_checker.corrected_score(@wms_array)

    find_sum = FindSum.new(@wms_array)
    @wms_array = find_sum.sum_score(@wms_array)

    @wms_scores_and_title = wms_test.scores_and_title(@wms_array)

    # [[1人目の問題Aの得点, 1人目の問題Bの得点], [2人目の問題Aの得点, 2人目の問題Bの得点]...]の形に変換
    @wms_scores_per_person = @wms_scores_and_title.slice_before('論理的記憶').to_a

    # [問題Aの得点, 問題Bの得点]に整形
    @wms_scores = @wms_scores_per_person.map! do |one_person_data|
      shape(one_person_data)
    end

    # 得点を文字列型から整数型に変換する
    @wms_scores = alter_string_to_number(@wms_scores)

    # IDとデータをペアにする
    @results = pair(@subjects, @wms_scores)

    p @results = sum_check(@results)
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
