# frozen_string_literal: true

require 'google/apis/drive_v3'
require 'google/api_client/client_secrets'
require 'roo'
require 'rubyXL'
require 'rubyXL/convenience_methods'
require 'pdf/reader'

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
    # テキストファイルから被験者IDを取り出す
    get_suject_id_from_text
    # テキストファイルの文字列を配列に格納
    convert_line_into_array

    convert_one_into_slash(@all_texts)
    separate_scores(@all_texts)
    pull_out_scores(@all_texts)
    separate_each_pdf(@all_scores)
    # 図形の得点を取得
    figure_scores_from_text(@each_pdf_scores)

    # テキストファイルからスラッシュを目印にPDFの得点データを取得
    test_scores_from_text(@each_pdf_scores)
    connect_scores(@figure_scores, @test_scores)

    # 得点データをエクセルに出力
    export_to_excel(@new_pdf_scores, @subject_ids)

    # 得点の合計が正しいかチェックする
    calc_score_sum(@pdf_length)

    # エクセルから得点を取得
    get_scores_from_excel

    # PDFデータとExcelデータを照合
    compare(@new_pdf_scores, @excel_scores)
    # 照合が完了したらファイルを削除
    delete_files
    # エラーが発生したらファイルを削除
    FileUtils.rm_r(Dir.glob(Rails.root.join('public/uploads/*.pdf').to_s))
    FileUtils.rm_r(Dir.glob(Rails.root.join('tmp/txt/*.txt').to_s))
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

  # テキストファイルから被験者IDを取り出す
  def get_suject_id_from_text
    @subject_ids = []
    File.open("./tmp/txt/sample.txt", 'r') do |f|
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
  end

  # テキストファイルの文字列を配列に格納する
  def convert_line_into_array
    @all_texts = []
    File.open('./tmp/txt/sample.txt', 'r') do |f|
      f.each_line do |line|
        @all_texts << line.strip
      end
    end
  end

  # Google Drive OCRでスラッシュが誤って1と読み取られた場合、1を/に変換する
  # スラッシュを目印に得点を取得しており、得点を取得のためのデータ加工処理
  def convert_one_into_slash(all_texts)
    # 「1/6」がOCRで「116」と誤って読み取られているのを「1/6」に修正
    @all_texts = all_texts.map! do |string|
      string[1] = '/' if string.match?(/^[0-6]1[0-6]$/)
      string unless string.nil?
    end
  end

  # 図形の得点と項目の得点が同じ行にあったら別の行に分ける 例：[0]3/5
  def separate_scores(all_texts)
    @all_texts = all_texts.map do |string|
      if string.match?(/\[0\]|\[O\]|\[o\]|\[⚪︎\]|\[○\]|\[x\]|\[X\]|\[×\]/) && string.match?(/[0-6]\/[0-6]/)
        figure_score = string[/\[0\]|\[O\]|\[o\]|\[⚪︎\]|\[○\]|\[x\]|\[X\]|\[×\]/]
        test_score = string[/[0-6]\/[0-6]/]
        string = [figure_score, test_score]
      else
        string
      end
    end
    @all_texts.flatten!
  end

  # テキストから得点のみ抽出する
  def pull_out_scores(all_texts)
    @all_scores = all_texts.map do |string|
      string if string.match?(/\[.\]|\/|検査実施者/)
    end
    @all_scores.delete_if{|s| s == nil}
  end

  # PDF1枚ごとの配列に分割する
  def separate_each_pdf(all_scores)
    @all_scores = all_scores.deep_dup
    one_pdf = []
    @each_pdf_scores = []
    @all_scores.each do |string|
      if string.match?(/検査実施者/)
        one_pdf << string
        @each_pdf_scores << one_pdf
        one_pdf = []
      else
        one_pdf << string
      end
    end
    @each_pdf_scores
  end

  # テキストファイルから図形の得点を取得
  def figure_scores_from_text(each_pdf_scores)
    pdf_scores = each_pdf_scores.deep_dup
    @figure_scores = []
    pdf_scores.each do |pdf|
      count = 0
      one_pdf_figure_scores = []
      pdf.each do |string, s_i|
        # 図形の得点データを取得（図形のスコアは[0][O][o][○][⚪︎][x][X][×]のいずれか）
        if count < 5 
          if string.match?(/\[0\]|\[O\]|\[o\]|\[⚪︎\]|\[○\]/)
            one_pdf_figure_scores << 1
            count += 1
          elsif string.match?(/\[x\]|\[X\]|\[×\]/)
            one_pdf_figure_scores << 0
            count += 1
          end
        end
      end
      @figure_scores << one_pdf_figure_scores
    end
  end

  def test_scores_from_text(each_pdf_scores)
    pdf_scores = each_pdf_scores.deep_dup
    @test_scores = []
    # # スラッシュを目印に得点を取得
    pdf_scores.each do |pdf|
      one_pdf_test_scores = []
      pdf.each do |string|
        if string.match?(/\//)
          # スラッシュを目印にスラッシュの直前の得点を取得
          if get_score_before_slash(string)
            one_pdf_test_scores << get_score_before_slash(string)
          end
        end
      end
      @test_scores << one_pdf_test_scores
    end
  end

  # スラッシュを目印にスラッシュの直前の得点を取得（合計のみ2ケタ、それ以外は1ケタ）
  def get_score_before_slash(string)
    
    if string[0] == '/'
      string = '読みとり不可'
      return string
    elsif string.match?(/[^0-9]\/[0-6]/) # "0/1"のはずが"/1"と取得できていないバグがあったため追加
      string = '読みとり不可'
      return string
    elsif string.match?(/[0-9][0-9]\/30$/) # 合計得点が2ケタの場合
      string = string[0, 2]
      return string
    elsif string.match?(/[0-9]\/30$/) # 合計得点が1ケタの場合
      string = string[0]
      return string
    else
      # スラッシュの前の数字を取得
      # [0-6]/の部分文字列をもつ かつ '合計得点'は含まない
      if string[/[0-6]\//] && !string.include?('合計得点')
        string = string[/[0-6]\//][0].to_i
        return string
      end
    end
  end

  def connect_scores(figure_scores, test_scores)
    @new_pdf_scores = []
    figure_scores.each_with_index do |_, i|
      @new_pdf_scores << figure_scores[i].concat(test_scores[i])
    end
    @pdf_length = @new_pdf_scores.length
    return @new_pdf_scores, @pdf_length
  end

  # PDFから取得した得点をExcelに書き出す
  def export_to_excel(new_pdf_scores, subject_ids)
    pdf_scores_for_excel = new_pdf_scores.deep_dup
    workbook = RubyXL::Workbook.new
    worksheet = workbook[0]

    @excel_column_titles = %w(\  被験者番号 トレイルメイキング 立方体 時計[輪郭] 時計[数字] 時計[針] 視空間\ /5 命名\ /3 数唱\ /2 ひらがな\ /1 100-7\ /3 復唱\ /2 語想起\ /1 抽象概念\ /2 遅延再生\ /5 見当識\ /6 MoCA合計\ /30)

    # Excelの1行目に項目名を書き出す
    @excel_column_titles.each_with_index do |title, i|
      worksheet.add_cell(0, i, title)
    end

    # 1人ずつ格納されている得点配列に行番号と被験者IDを追加
    pdf_scores_for_excel.map.with_index do |subject, i|
      subject.unshift(i+1)
      subject.insert(1, subject_ids[i])
    end

    # PDFから取得した得点を行ごとにExcelに書き出す（1行ごとに1人分の得点が格納されている）
    pdf_scores_for_excel.each_with_index do |subject, subject_i|
      subject_num = subject_i + 1
      subject.each_with_index do |score, score_i|
        worksheet.add_cell(subject_num, score_i, score)
      end
    end
    
    @scores_in_excel = workbook.write(Rails.root.join('public', 'uploads', 'sample.xlsx'))
  end

  def calc_score_sum(pdf_length)
    file_path = Dir.glob(Rails.root.join('public/uploads/*.xlsx').to_s).first
    workbook = RubyXL::Parser.parse(file_path)
    worksheet = workbook[0]
    
    for i in 1..pdf_length
      sum_score = 0
      for j in 7..16
        if worksheet[i][j] == '読みとり不可'
          worksheet[i][j] = 0
          cell_score = worksheet[i][j].value.to_i
          sum_score += cell_score
        else
          cell_score = worksheet[i][j].value.to_i
          sum_score += cell_score
        end
      end
      moca_sum = worksheet[i][17].value.to_i

      # 1行ごと各項目をすべて足した値が合計と等しいかを確認する
      if sum_score != moca_sum
        # 等しくなければセルの色を変更し目立たせる
        worksheet.sheet_data[i][17].change_fill('ff6666')
      end
    end

    # Excelの変更を上書きする
    workbook.write(file_path)
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
      row.values_at('被験者番号', 'トレイルメイキング', '立方体', '時計[輪郭]', '時計[数字]' ,'時計[針]', '視空間 /5', '命名 /3', '数唱 /2', 'ひらがな /1', '100-7 /3', '復唱 /2', '語想起 /1', '抽象概念 /2', '遅延再生 /5', '見当識 /6', 'MoCA合計 /30')
    end
    @excel_scores.each do |person|
      person.shift
    end
  end

  # PDFデータとExcelデータを照合する
  def compare(new_pdf_scores, excel_scores)
    if new_pdf_scores.eql? excel_scores
      p @conclusion = "すべて正しいです"
    else
      p @conclusion = "間違いがあります"
    end

    @all_result = []

    @error_count = 0
    new_pdf_scores.each_with_index do |pdf, i|
      @personal_result = []
      pdf.each_with_index do |_, j|
        if new_pdf_scores[i][j] == '読みとり不可' || excel_scores[i][j] == '読みとり不可'
          @result = '読み取れていません'
          @error_count += 1
        elsif new_pdf_scores[i][j] == excel_scores[i][j]
          @result = '一致しています'
        else
          @result = '一致しません'
          @error_count += 1
        end
        @personal_result << @result
      end
      @all_result << @personal_result
    end
  end

  # ローカルからファイルを削除する
  def delete_files
    # FileUtils.rm_r(Dir.glob(Rails.root.join('public/uploads/*.xlsx').to_s))
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
