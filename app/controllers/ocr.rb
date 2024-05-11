require 'google/apis/drive_v3'
require 'google/api_client/client_secrets'

# client_secret.jsonファイルを読み取ってオブジェクトを作成
client_secrets = Google::APIClient::ClientSecrets.load
auth_client = client_secrets.to_authorization
auth_client.update!(
  :scope => 'https://www.googleapis.com/auth/drive.metadata.readonly',
  :redirect_uri => 'http://localhost',
  :additional_parameters => {
    "access_type" => "offline",         # offline access
    "include_granted_scopes" => "true"  # incremental auth
  }
)

auth_uri = auth_client.authorization_uri.to_s
redirect_to auth_uri

