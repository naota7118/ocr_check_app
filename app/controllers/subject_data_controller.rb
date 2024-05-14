class SubjectDataController < ApplicationController

  def index  
    require 'google/apis/drive_v3'
    require 'google/api_client/client_secrets'
  
    # client_secret.jsonファイルを読み取ってオブジェクトを作成
    client_secrets = Google::APIClient::ClientSecrets.load
    auth_client = client_secrets.to_authorization
    auth_client.update!(
      :scope => 'https://www.googleapis.com/auth/drive.metadata.readonly',
      :redirect_uri => 'http://localhost:3000/subject_data',
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
      drive = Google::Apis::DriveV3::DriveService.new
      drive.authorization = auth_client

      # ファイル一覧を表示
      # files = drive.list_files
      # @data = JSON.pretty_generate(files.to_h)

      # Search for files in Drive (first page only)
      files = drive.list_files(q: "name contains 'エクセルデータのサンプル.pdf'")
      files.files.each_with_index do |file, i|
        drive.get_file(file.id, download_dest: "/Users/naota7118/ocr_check_app/tmp/sample.pdf")       
        @data = drive.export_file(file.id, 'text/plain', download_dest: "/Users/naota7118/ocr_check_app/tmp/sample.txt")
      end
      
      
    end
  end

end

