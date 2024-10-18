# frozen_string_literal: true

require 'google/apis/drive_v3'
require 'google/api_client/client_secrets'
require 'roo'
require 'rubyXL'

class MocaDataController < ApplicationController
  # ファイルアップロード用のビューを返す
  def index; end

  # 照合結果を表示
  def result
    # Google認証
    pass_authentication
    return if performed?

    # Google Drive APIを用いてPDF→Googleドキュメント→テキストに変換
    convert(@drive)
    # テキストファイルからスラッシュを目印に得点データを取得
    get_scores_from_text
    # 得点データをエクセルに出力
    export_to_excel(@pdf_data)
    # エクセルから得点を取得
    get_scores_from_excel

    # PDFデータとExcelデータを照合
    verify_suject_id(@pdf_data, @excel_data)
    # 照合が完了したらファイルを削除
    delete_files
  end

  # ファイルをアップロード
  def upload
    uploaded_file = params[:upload]
    file_path = Rails.root.join("public/uploads/#{uploaded_file.original_filename}")
    File.binwrite(file_path, uploaded_file.read)
    redirect_to moca_result_path
  end

  # PDFファイルからテキストファイルに変換
  def convert(drive)
    file_path = Dir.glob(Rails.root.join('public/uploads/*.pdf').to_s)
    # PDFファイルをGoogleドライブにアップロード
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
    string[1] = '/' if string.match?(/^[0-6]{1}1{1}[0-6]{1}$/)

    return unless string.chars.include?('/') && string.match?(%r{^[0-9/\[]})

    string.chars
  end

  # 得点データx/yのうちxだけを取得
  def score(revised_chars)
    if revised_chars.first == '/'
      @pdf_scores << '読みとり不可'
    else
      revised_chars.each_with_index do |char, i|
        next unless char == '/'

        # ["〇", "〇", "/", "3", "0"]は/の前の2ケタを取得
        @pdf_scores << if (revised_chars[i + 1].to_i == 3 && revised_chars[i + 2].to_i.zero?) && revised_chars.last == '0'
          [revised_chars[i - 2].to_i, revised_chars[i - 1].to_i].join
        else
          revised_chars[i - 1]
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
    worksheet.add_cell(0, 2, '視空間 /5')
    worksheet.add_cell(0, 3, '命名 /3')
    worksheet.add_cell(0, 4, '数唱 /2')
    worksheet.add_cell(0, 5, 'ひらがな /1')
    worksheet.add_cell(0, 6, '100-7 /3')
    worksheet.add_cell(0, 7, '復唱 /2')
    worksheet.add_cell(0, 8, '語想起 /1')
    worksheet.add_cell(0, 9, '抽象概念 /2')
    worksheet.add_cell(0, 10, '遅延再生 /5')
    worksheet.add_cell(0, 11, '見当識 /6')
    worksheet.add_cell(0, 12, 'MoCA合計 /30')

    pdf_data.each_with_index do |subject_data, sub_i|
      worksheet.add_cell(sub_i+1, 0, sub_i+1)
      worksheet.add_cell(sub_i+1, 1, "CHIBA#{sub_i+1}")
      worksheet.add_cell(sub_i+1, 2, pdf_data[sub_i][0])
      worksheet.add_cell(sub_i+1, 3, pdf_data[sub_i][1])
      worksheet.add_cell(sub_i+1, 4, pdf_data[sub_i][2])
      worksheet.add_cell(sub_i+1, 5, pdf_data[sub_i][3])
      worksheet.add_cell(sub_i+1, 6, pdf_data[sub_i][4])
      worksheet.add_cell(sub_i+1, 7, pdf_data[sub_i][5])
      worksheet.add_cell(sub_i+1, 8, pdf_data[sub_i][6])
      worksheet.add_cell(sub_i+1, 9, pdf_data[sub_i][7])
      worksheet.add_cell(sub_i+1, 10, pdf_data[sub_i][8])
      worksheet.add_cell(sub_i+1, 11, pdf_data[sub_i][9])
      worksheet.add_cell(sub_i+1, 12, pdf_data[sub_i][10])
    end
    workbook.write(Rails.root.join('public', 'uploads', 'sample.xlsx'))
  end

  def get_scores_from_excel
    # Excelからデータを取得
    Dir.glob(Rails.root.join('public/uploads/*.xlsx').to_s).each do |excel|
      @xlsx = Roo::Excelx.new(excel)
    end
    @excel_data = @xlsx.parse(headers: true, clean: true)
    # ヘッダー行は不要
    @excel_data.shift
    # 照合に必要な列だけ取得
    @excel_data.map! do |row|
      row.values_at('被験者番号', '視空間 /5', '命名 /3', '数唱 /2', 'ひらがな /1', '100-7 /3', '復唱 /2', '語想起 /1', '抽象概念 /2', '遅延再生 /5', '見当識 /6', 'MoCA合計 /30')
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
          result_element = [pdf_data[sub_i][sco_i], subject[sco_i], '読み取れていません']
          @count += 1
        elsif excel_data[sub_i][sco_i].to_i == pdf_data[sub_i][sco_i].to_i
          result_element = [pdf_data[sub_i][sco_i].to_i, excel_data[sub_i][sco_i].to_i, '一致しています']
          else
            result_element = [pdf_data[sub_i][sco_i].to_i, excel_data[sub_i][sco_i].to_i, '一致しません']
            @count += 1
        end
        @personal_result << result_element
      end
      @result_data << @personal_result
    end
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
        'access_type' => 'online',
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
