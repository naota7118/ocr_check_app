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

      # ファイルをアップロード
      metadata = Google::Apis::DriveV3::File.new(title: 'My document')
      metadata = drive.create_file(metadata, upload_source: './tmp/sample.pdf', content_type: 'application/pdf')

      # Googleドキュメント形式に変換
      converted_file = drive.copy_file(metadata.id, Google::Apis::DriveV3::File.new(mime_type: 'application/vnd.google-apps.document'))
      
      # ファイルを出力
      drive.export_file(converted_file.id, 'text/plain', download_dest: './tmp/sample.txt')
    end
  end

end

