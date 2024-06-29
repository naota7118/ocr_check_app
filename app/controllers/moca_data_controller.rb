# frozen_string_literal: true

require 'google/apis/drive_v3'
require 'google/api_client/client_secrets'
require 'csv'
require 'roo'

class MocaDataController < ApplicationController
  # ファイルをアップロード
  def create
    uploaded_files = params[:uploads]
    uploaded_files.shift # 最初の要素を削除
    uploaded_files.each do |uploaded_file|
      file_path = Rails.root.join("public/uploads/#{uploaded_file.original_filename}")
      File.open(file_path, 'w+b') do |file|
        file.write(uploaded_file.read)
      end
    end

    redirect_to moca_result_path
  end

  # PDFファイルからテキストファイルに変換
  def convert(drive)
    # Google Driveにファイルをアップロード
    metadata = Google::Apis::DriveV3::File.new(title: 'My document')
    # PDFファイルのパス取得してupload_sourceに代入
    Dir.glob(Rails.root.join('public/uploads/*.pdf').to_s).each do |pdf|
      metadata = drive.create_file(metadata, upload_source: pdf, content_type: 'application/pdf')
    end

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
    defects = %w(010 011 012 013 014 015 016 116 112 113 114 115 116 212 213 214 215 216 313 314 315 316 414 415 416 515 516 616)
    if defects.include?(string)
      chars = string.split('')
      chars.each do |char|
        chars[1] = '/'
      end
    end
    chars
  end

  # 得点データx/yのうちxだけを取得
  def score(revised_chars, char, i)
    if char == '/'
      # /の前後が数値でなければ対象外
      int = revised_chars[i+1].to_i
      if int != 0
        # /の後ろが30(1つ後ろが3 && 2つ後ろが0)なら2つ前と1つ前を表示
        if revised_chars[i+1].to_i == 3 && revised_chars[i+2].to_i == 0
          # 01→1, 03→3に修正
          if revised_chars[i-2].to_i == 0
            @pdf_scores << revised_chars[i-1].to_i
          # 26/30は得点ではないので除外
          elsif revised_chars[i-2].to_i == 2 && revised_chars[i-1].to_i == 6
            @pdf_scores << [revised_chars[i-2].to_i, revised_chars[i-1].to_i].join
            @pdf_scores.pop
          else
            # 1/3が31と表示されるので2ケタ以上は1の位のみ表示
            if ([revised_chars[i-2].to_i, revised_chars[i-1].to_i].join).length == 1
              @pdf_scores << [revised_chars[i-2].to_i, revised_chars[i-1].to_i].join
            else
              @pdf_scores << revised_chars[i-1]
            end
          end
        else # それ以外なら1つ前だけ表示
          if revised_chars.first == '/'
            @pdf_scores << '読みとり失敗'
          else
            @pdf_scores << revised_chars[i-1]
          end
        end
      end
    end
  end

  # テキストファイルから得点データを取得
  def get_scores_from_text
    @pdf_scores = []
    File.open('./tmp/txt/sample.txt', 'r') do |f|
      f.each_line do |line|
        chars = line.strip.split('')
        revised_chars = one_to_slash(chars)
        if revised_chars.include?('/')
          revised_chars.each_with_index do |char, i|
            score(revised_chars, char, i)
          end
        end
      end
    end
  end

  # エクセルファイルから得点データを取得
  def get_id_from_excel
    # Excelからデータを取得
    Dir.glob(Rails.root.join('public/uploads/*.xlsx').to_s).each do |excel|
      @xlsx = Roo::Excelx.new(excel)
    end
    @excel_data = @xlsx.parse(headers: true, clean: true)
    # ヘッダー行は不要
    @excel_data.shift
    # 被験者番号から時計までの列は不要
    6.times { @excel_data.first.shift }
    # 語想起数は不要
    @excel_data.delete_at(8)
    # 照合のために必要なデータだけ格納
    @scales = []
    @excel_scores = []
    @excel_data.first.each do |k, v|
      @scales << k
      @excel_scores << v 
    end
    return @scales, @excel_scores
  end

  # PDFデータとExcelデータを照合する
  def verify_suject_id(pdf_data, excel_data)
    @count = 0
    @result = []
    pdf_data.each_with_index do |_, i|
      if pdf_data[i].to_i == excel_data[i]
        result_element = [pdf_data[i], excel_data[i], "一致しています"]
      else
        result_element = [pdf_data[i], excel_data[i], "一致しません"]
        @count += 1
      end
      @result << result_element
    end
  end

  def index; end

  # 照合して結果を表示
  def result
    pass_authentication
    return if performed?

    convert(@drive)
    get_scores_from_text
    get_id_from_excel

    # PDFデータとExcelデータを照合する
    verify_suject_id(@pdf_scores, @excel_scores)
    # 照合が完了したらファイルを削除する
    delete_files
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
      scope: 'https://www.googleapis.com/auth/drive.metadata.readonly',
      redirect_uri: 'http://localhost:3000/moca_result',
      additional_parameters: {
        'access_type' => 'offline',         # offline access
        'include_granted_scopes' => 'true'  # incremental auth
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
      @drive = Google::Apis::DriveV3::DriveService.new
      @drive.authorization = auth_client
    end
  end
end