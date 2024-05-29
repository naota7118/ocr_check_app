require 'google/apis/drive_v3'
require 'google/api_client/client_secrets'
require 'csv'
require 'roo'
require 'Fileutils'

class SubjectDataController < ApplicationController

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

    redirect_to result_path
  end

  def convert(drive) #PDFファイルからテキストファイルに変換
    # Google Driveにファイルをアップロード
    metadata = Google::Apis::DriveV3::File.new(title: 'My document')
    # PDFファイルのパス取得してupload_sourceに代入
    Dir.glob("#{Rails.root.join("public/uploads/*.pdf")}").each do |pdf|
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

  def get_id_from_text #テキストファイルからIDを取得
    @pdf_id = []
    File.open("./tmp/txt/sample.txt", "r") do |f|
      f.each_line do |l|
        s = l.chomp.strip
        if s.include?('CHIBA')
          @pdf_id.push(s)
        end
      end
    end
  end

  def get_id_from_excel #エクセルファイルからIDを取得
    # Excelからデータを取得
    Dir.glob("#{Rails.root.join("public/uploads/*.xlsx")}").each do |excel|
      @xlsx = Roo::Excelx.new(excel)
    end
    @excel_data = @xlsx.parse(headers: true, clean: true)

    #Excelからidだけ取得
    @excel_id = @excel_data.map do |hash|
      hash['被験者番号']
    end
    # 配列の先頭はidではないので削除
    @excel_id.shift
  end

  # PDFデータとExcelデータを照合する
  def verify_suject_id(pdf_data, excel_data)
    # 不一致の件数をカウントする
    @count = 0
    @result = []
    pdf_data.each_with_index do |_, i|
      if pdf_data[i] == excel_data[i]
        @result << "一致しています"
      else
        @result << "一致しません。\n
        PDFのIDは#{pdf_data[i]}です。\n
        ExcelのIDは#{excel_data[i]}です。"
        @count += 1
      end
    end

  end

  def index
    
  end

  def result #照合して結果を表示
    pass_authentication
    return if performed?
    convert(@drive)
    get_id_from_text
    get_id_from_excel
    # PDFデータとExcelデータを照合する
    verify_suject_id(@pdf_id, @excel_id)
    # 照合が完了したらファイルを削除する
    delete_files
  end

  # ローカルからファイルを削除する
  def delete_files
    FileUtils.rm_r(Dir.glob("#{Rails.root.join("public/uploads/*.xlsx")}"))
    FileUtils.rm_r(Dir.glob("#{Rails.root.join("public/uploads/*.pdf")}"))
    FileUtils.rm_r(Dir.glob("#{Rails.root.join("tmp/txt/*.txt")}"))
  end

  private
  def pass_authentication # Google API認証を通す
    # client_secret.jsonファイルを読み取ってオブジェクトを作成
    client_secrets = Google::APIClient::ClientSecrets.load
    auth_client = client_secrets.to_authorization
    auth_client.update!(
      :scope => 'https://www.googleapis.com/auth/drive.metadata.readonly',
      :redirect_uri => 'http://localhost:3000/result',
      :additional_parameters => {
        "access_type" => "offline",         # offline access
        "include_granted_scopes" => "true"  # incremental auth
      }
    )
    if request.params['code'] == nil # 認証コードを持っていなかった場合
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