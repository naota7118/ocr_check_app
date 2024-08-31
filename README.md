# OCR Check

現在の仕事で、紙データとエクセルデータの照合作業に時間がかかる問題を抱えていました。  

そこで、OCR技術を活用して、照合作業を効率化するアプリ「OCR Check」を開発しました。

![OCR Check説明資料](https://github.com/user-attachments/assets/ab58a5cb-d9d7-4f07-a7ec-a0c19f1a6678)

具体的には、PDFから得点データを抽出し、Excelデータと一致しているかを確認します。

## トップページ
![トップページ](https://github.com/user-attachments/assets/2f007153-77e6-4e00-afa4-6814d645da81)

## 解説記事(Qiita)
OCR Checkを作ろうと考えた背景やユーザーインタビューの内容は、こちらの記事で詳しく解説しています。

[OCR Check開発の背景・ユーザーインタビュー・技術を選んだ理由](https://qiita.com/naota7118/private/1790c44202a52e992170)

## 説明動画
動画で実際にどのように照合が行われているか説明しています。

https://github.com/user-attachments/assets/97b79b85-ff37-49b2-be92-716a7f51181b

## 特に見ていただきたい点

- バックエンド
  - 自分でメソッドを作り連携させて照合を実現している
  - 公式ドキュメントなどを参考にOAuth認証を実現した
- インフラ
  - DockerとGitHub Actionsを使って本番環境でのテストおよびデプロイを自動化している
- その他
  - 職場の上司にヒアリングしてから開発を始め、ユーザーインタビューを行い改善している

## 使用した技術
- バックエンド
  - Ruby 3.3.0
  - Ruby on Rails 7.1.3.2
  - Apache(プロキシサーバー化)
  - Rubocop
  - Rspec
- フロントエンド
  - HTML/CSS
  - JavaScript
- インフラ
  - Docker
  - AWS(EC2, VPC, Route53, ACM, ALB, WAF)
  - GitHub Actions CI/CDを自動化
- ライブラリ
  - google/apis/drive_v3 PDFからテキスト抽出
  - google/api_client/client_secrets OAuth認証で必要
  - roo エクセルからデータ取得
  - high_voltage 静的なページをコントローラ使わず表示

## インフラ構成図
![ocrcheck_infra](https://github.com/user-attachments/assets/63c14598-eee1-46cc-a935-9bf8d3fc64f3)