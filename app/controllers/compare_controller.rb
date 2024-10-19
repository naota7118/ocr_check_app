# frozen_string_literal: true

require 'google/apis/drive_v3'
require 'google/api_client/client_secrets'
require 'roo'
require 'rubyXL'

class CompareController < ApplicationController
  # ファイルをアップロード
  def create
    uploaded_file = params[:upload]
    file_path = Rails.root.join("public/uploads/#{uploaded_file.original_filename}")
    File.binwrite(file_path, uploaded_file.read)
    redirect_to compare_result_path
  end

  # PDFファイルからテキストファイルに変換
  def convert(drive)
    # Google Driveにファイルをアップロード
    # metadata = Google::Apis::DriveV3::File.new(title: 'My document')
    file_path = Dir.glob(Rails.root.join('public/uploads/*.pdf').to_s)
    metadata = drive.create_file(metadata, upload_source: file_path.first, content_type: '/pdf')

    # Googleドキュメント形式に変換
    converted_file = drive.copy_file(metadata.id, Google::Apis::DriveV3::File.new(mime_type: 'application/vnd.google-apps.document'))

    # テキストファイルを出力
    drive.export_file(converted_file.id, 'text/plain', download_dest: './tmp/txt/sample.txt')

    # GoogleドライブからPDFファイルを削除する
    drive.delete_file(metadata.id)
    # GoogleドライブからGoogleドキュメントファイルを削除する
    drive.delete_file(converted_file.id)
  end

  # 116を1/6に変換
  def one_to_slash(chars)
    string = chars.join
    string[1] = '/' if string.match?(/^[0-6]1[0-6]$/)

    # 0から9の数値に続いて'128'を見つけたら1を/に変換する
    if string.match?(/[0-9]128$/)
      string.gsub!(/128/, '/28')
    end
    
    if string.match?(%r{^[0-9/]})
      string.chars
    end
  end

  # 得点データx/yのうちxだけを取得
  def score(revised_chars)
    if revised_chars.first == '/'
      @pdf_scores << '読みとり不可'
    # 1/4の1が読み取れていない場合があるので条件を追加(14と出力される)
    # /^1{1[0-6]{1}$/にマッチしたら'読みとり不可'と表示する
    elsif revised_chars.join.match?(/^1{1}[0-6]{1}$/)
      @pdf_scores << '読みとり不可'
    elsif revised_chars.join.match?(/[0-9]\/28$/) && revised_chars.join.length == 4 # 1桁の場合
      @pdf_scores << revised_chars[0]
    elsif revised_chars.join.match?(/[0-9][0-9]\/28$/) && revised_chars.join.length == 5 #2桁の場合
      @pdf_scores << revised_chars.join[0, 2]
    elsif revised_chars.include?('/')
      # スラッシュの前の数字を取得
      revised_chars.each_with_index do |char, i|
        if char == '/'
          @pdf_scores << revised_chars[i - 1]
        end
      end
    end
  end

  # テキストファイルから得点データを取得
  def get_scores_from_text
    @pdf_scores = []
    File.open('./tmp/txt/sample.txt', 'r') do |f|
      f.each_line do |line|
        chars = line.strip.chars

        # 空白文字を削除
        chars.delete_if { |char| char == ' ' }

        # スラッシュまたは1が含まれていないものは対象外
        if chars.include?('/') || chars.include?('1')
          # 116→1/6に変換
          revised_chars = one_to_slash(chars)
          # nil以外を出力
          score(revised_chars) unless revised_chars.nil?
        end
      end
    end
    # 1人ずつの配列に区切る
    @pdf_data = []
    @pdf_scores.each_slice(11) { |subject| @pdf_data << subject }
  end

  # エクセルファイルに得点を出力
  def export_to_excel(pdf_data)

    # Excelからデータを取得
    workbook = RubyXL::Workbook.new
    worksheet = workbook[0]
    worksheet.add_cell(0, 0, '')
    worksheet.add_cell(0, 1, '被験者番号')
    worksheet.add_cell(0, 2, 'trail /1')
    worksheet.add_cell(0, 3, 'cube /1')
    worksheet.add_cell(0, 4, 'clock /3')
    worksheet.add_cell(0, 5, '空間把握 /5')
    worksheet.add_cell(0, 6, '名前 /2')
    worksheet.add_cell(0, 7, '加算 /2')
    worksheet.add_cell(0, 8, 'いろ /1')
    worksheet.add_cell(0, 9, '50-8 /4')
    worksheet.add_cell(0, 10, '暗唱 /2')
    worksheet.add_cell(0, 11, '種類 /1')
    worksheet.add_cell(0, 12, '種類 想起数')
    worksheet.add_cell(0, 13, '類似 /2')
    worksheet.add_cell(0, 14, '想起 /5')
    worksheet.add_cell(0, 15, '日時 /4')
    worksheet.add_cell(0, 16, '合計 /28')

  
    pdf_data.each_with_index do |subject_data, sub_i|
      worksheet.add_cell(subject_number, 0, 'CHIBA001')
      worksheet.add_cell(subject_number, 1, pdf_data[sub_i][0])
      worksheet.add_cell(subject_number, 2, pdf_data[sub_i][1])
      worksheet.add_cell(subject_number, 3, pdf_data[sub_i][2])
      worksheet.add_cell(subject_number, 4, pdf_data[sub_i][3])
      worksheet.add_cell(subject_number, 5, pdf_data[sub_i][4])
      worksheet.add_cell(subject_number, 6, pdf_data[sub_i][5])
      worksheet.add_cell(subject_number, 7, pdf_data[sub_i][6])
      worksheet.add_cell(subject_number, 8, pdf_data[sub_i][7])
      worksheet.add_cell(subject_number, 9, pdf_data[sub_i][8])
      worksheet.add_cell(subject_number, 10, pdf_data[sub_i][9])
      worksheet.add_cell(subject_number, 11, pdf_data[sub_i][10])
    end

    workbook.write('example.xlsx')
    binding.pry
    @excel_data = @xlsx.parse(headers: true, clean: true)
    # ヘッダー行は不要
    @excel_data.shift
    # 照合に必要な列だけ取得
    @excel_data.map! do |row|
      row.values_at('被験者番号', '空間把握_/5', '名前_/2', '加算_/2', 'いろ_/1', '50-8_/4', '暗唱_/2', '種類_/1', '類似_/2', '想起_/5', '日時_/4', '合計_/28')
    end
    @subject_numbers = []
    @excel_data.each do |person|
      @subject_numbers << person.first
      person.shift
    end
  end

  # PDFデータとExcelデータを照合する
  def verify_suject_id(pdf_data, excel_data)
    @count = 0
    @result_data = []
    excel_data.each_with_index do |subject, sub_i|
      @personal_result = []
      subject.each_with_index do |_score, sco_i|
        if pdf_data[sub_i][sco_i] == '読みとり不可'
          result_element = [pdf_data[sub_i][sco_i], subject[sco_i], '一致しません']
          @count += 1
        elsif subject[sco_i] == pdf_data[sub_i][sco_i].to_i
          result_element = [pdf_data[sub_i][sco_i].to_i, subject[sco_i], '一致しています']
          else
            result_element = [pdf_data[sub_i][sco_i].to_i, subject[sco_i], '一致しません']
            @count += 1
        end
        @personal_result << result_element
      end
      @result_data << @personal_result
    end
  end

  def index; end

  # 照合して結果を表示
  def result
    start_time = Time.now

    pass_authentication
    return if performed?

    if convert(@drive) == 'fileIdInUse: A file already exists with the provided ID.'
      FileUtils.rm_r(Dir.glob(Rails.root.join('public/uploads/*.pdf').to_s))
      redirect_to compare_index_path
      return
    else
      get_scores_from_text
      export_to_excel(@pdf_data)
  
      # PDFデータとExcelデータを照合する
      verify_suject_id(@pdf_data, @excel_data)
      # 照合が完了したらファイルを削除する
      delete_files
    end

    p "照合処理にかかる時間 #{Time.now - start_time}s"
  end

  # ローカルからファイルを削除する
  def delete_files
    FileUtils.rm_r(Dir.glob(Rails.root.join('public/uploads/*.xlsx').to_s))
    FileUtils.rm_r(Dir.glob(Rails.root.join('public/uploads/*.pdf').to_s))
    FileUtils.rm_r(Dir.glob(Rails.root.join('tmp/txt/*.txt').to_s))
  end

  private

  # Google API認証を通す
  def pass_authentication
    # client_secret.jsonファイルを読み取ってオブジェクトを作成
    client_secrets = Google::APIClient::ClientSecrets.load
    auth_client = client_secrets.to_authorization
    auth_client.update!(
      scope: 'https://www.googleapis.com/auth/drive',
      redirect_uri: Rails.application.credentials.dig(:google, :redirect_uri),
      additional_parameters: {
        'access_type' => 'online', # online access
        'include_granted_scopes' => 'true' # incremental auth
      }
    )
    if request.params['code'].nil? # 認証コードを持っていなかった場合
      auth_uri = auth_client.authorization_uri.to_s
      redirect_to auth_uri, allow_other_host: true
    else # 認証コードを持っている場合
      auth_client.code = request.params['code']
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
