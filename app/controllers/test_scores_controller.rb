# frozen_string_literal: true

require 'google/apis/drive_v3'
require 'google/api_client/client_secrets'
require 'roo'
require 'rubyXL'

class TestScoresController < ApplicationController
  # ファイルアップロード用のビューを返す
  def index; end

  # フォームで送られたPDFファイルを格納しresult関数を呼び出す
  def create
    uploaded_file = params[:upload]
    if uploaded_file
      file_path = Rails.root.join("public/uploads/#{uploaded_file.original_filename}")
      File.binwrite(file_path, uploaded_file.read)
      redirect_to test_scores_result_path
    end
  end

  # PDFとエクセルの得点データを照合し、結果を返す
  def result
    # Google認証
    pass_authentication
    return if performed?

    # Google Drive APIを用いてPDF→Googleドキュメント→テキストに変換
    convert_pdf_into_text(@drive)

    get_suject_id_from_pdf
    # テキストファイルからスラッシュを目印にPDFの得点データを取得
    get_scores_from_pdf
    # 得点データをエクセルに出力
    export_to_excel(@pdf_scores)
    # エクセルから得点を取得
    get_scores_from_excel

    # PDFデータとExcelデータを照合
    compare(@pdf_scores, @excel_scores)
    # 照合が完了したらファイルを削除
    delete_files
  end

  # PDFから照合処理に必要なテキストのみ抽出（Google Drive APIのOCR技術使用）
  def convert_pdf_into_text(drive)
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

  # Google Drive OCRでスラッシュが誤って1と読み取られた場合、1を/に変換する
  # スラッシュを目印に得点を取得しており、得点を取得のためのデータ加工処理
  def convert_one_into_slash(chars)
    string = chars.join
    string[1] = '/' if string.match?(/^[0-6]{1}1{1}[0-6]{1}$/)

    return unless string.chars.include?('/') && string.match?(%r{^[0-9/\[]})

    string.chars
  end

  # 得点データx/yのうちxだけを取得
  def score(revised_chars)
    if revised_chars.first == '/'
      @all_pdf_scores << '読みとり不可'
    elsif revised_chars.join.match?(/^1{1}[0-6]{1}$/)
      @all_pdf_scores << '読みとり不可'
    elsif revised_chars.join.match?(/[0-9]\/30$/) && revised_chars.join.length == 4 # 1桁の場合
      @all_pdf_scores << revised_chars[0]
    elsif revised_chars.join.match?(/[0-9][0-9]\/30$/) && revised_chars.join.length == 5 #2桁の場合
      @all_pdf_scores << revised_chars.join[0, 2]
    elsif revised_chars.include?('/')
      # スラッシュの前の数字を取得
      revised_chars.each_with_index do |char, i|
        if char == '/'
          @all_pdf_scores << revised_chars[i - 1]
        end
      end
    end
  end

  def get_suject_id_from_pdf
    @subject_ids = []
    File.open('./tmp/txt/sample.txt', 'r') do |f|
      f.each_line do |line|
        # テキストを1行ごとに1文字区切りの配列に変換
        chars_by_line = line.strip.chars
        # 配列の中の空白文字要素を削除
        chars_by_line.delete_if { |char| char == ' ' }
        new_line = chars_by_line.join
        if new_line.include?("Osaka") || new_line.include?("Oska")
          @subject_ids.push(new_line)
        end
      end
    end
    p @subject_ids
  end

  # テキストファイルから得点データを取得
  def get_scores_from_pdf
    @all_pdf_scores = []
    File.open('./tmp/txt/sample.txt', 'r') do |f|
      f.each_line do |line|
        # テキストを1行ごとに1文字区切りの配列に変換
        chars_by_line = line.strip.chars
        # 配列の中の空白文字要素を削除
        chars_by_line.delete_if { |char| char == ' ' }

        # スラッシュまたは1を目印に得点を取得
        if chars_by_line.include?('/') || chars_by_line.include?('1')
          # 116→1/6に変換
          revised_chars = convert_one_into_slash(chars_by_line)
          # nil以外を出力
          score(revised_chars) unless revised_chars.nil?
        end
      end
    end
    # 1人ずつの配列に区切る
    @pdf_scores = []
    @all_pdf_scores.each_slice(11) { |subject| @pdf_scores << subject }
  end

  # PDFから取得した得点をExcelに書き出す
  def export_to_excel(pdf_scores)
    workbook = RubyXL::Workbook.new
    worksheet = workbook[0]

    excel_column_titles = %w(\  被験者番号 視空間\ /5 命名\ /3 数唱\ /2 ひらがな\ /1 100-7\ /3 復唱\ /2 語想起\ /1 抽象概念\ /2 遅延再生\ /5 見当識\ /6 MoCA合計\ /30)

    # Excelの1行目に項目名を書き出す
    excel_column_titles.each_with_index do |title, i|
      worksheet.add_cell(0, i, title)
    end

    # 照合用の配列とは別にExcel書き出し用の配列を生成
    pdf_scores_with_id = pdf_scores.deep_dup

    # 1人ずつ格納されている得点配列に行番号と被験者番号を追加
    pdf_scores_with_id.map.with_index do |subject_data, i|
      subject_data.unshift(i)
      subject_data.insert(1, "CHIBA#{i}")
    end

    # PDFから取得した得点を行ごとにExcelに書き出す（1行ごとに1人分の得点が格納されている）
    pdf_scores_with_id.each_with_index do |subject_data, subject_i|
      subject_num = subject_i + 1
      subject_data.each_with_index do |score, score_i|
        worksheet.add_cell(subject_num, score_i, score)
      end
    end
    workbook.write(Rails.root.join('public', 'uploads', 'sample.xlsx'))
  end

  def get_scores_from_excel
    # Excelからデータを取得
    Dir.glob(Rails.root.join('public/uploads/*.xlsx').to_s).each do |excel|
      @xlsx = Roo::Excelx.new(excel)
    end
    @excel_scores = @xlsx.parse(headers: true, clean: true)
    # ヘッダー行は不要
    @excel_scores.shift
    # 照合に必要な列だけ取得
    @excel_scores.map! do |row|
      row.values_at('被験者番号', '視空間 /5', '命名 /3', '数唱 /2', 'ひらがな /1', '100-7 /3', '復唱 /2', '語想起 /1', '抽象概念 /2', '遅延再生 /5', '見当識 /6', 'MoCA合計 /30')
    end
    @excel_scores.each do |person|
      person.shift
    end
  end

  # PDFデータとExcelデータを照合する
  def compare(pdf_scores, excel_scores)
    @count = 0
    @all_result = []
    excel_scores.each_with_index do |subject, sub_i|
      @personal_result = []
      subject.each_with_index do |_score, sco_i|
        if pdf_scores[sub_i][sco_i] == '読みとり不可'
          result_element = [pdf_scores[sub_i][sco_i], subject[sco_i], '読み取れていません']
          @count += 1
        elsif excel_scores[sub_i][sco_i].to_i == pdf_scores[sub_i][sco_i].to_i
          result_element = [pdf_scores[sub_i][sco_i].to_i, excel_scores[sub_i][sco_i].to_i, '一致しています']
          else
            result_element = [pdf_scores[sub_i][sco_i].to_i, excel_scores[sub_i][sco_i].to_i, '一致しません']
            @count += 1
        end
        @personal_result << result_element
      end
      @all_result << @personal_result
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
