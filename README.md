# OCR Check

現在の仕事で、紙データとエクセルデータの照合で時間がかかる問題を抱えています。  

OCR技術を活用して、書類データとPCデータの照合チェックを効率化するためのアプリです。

## 解説記事(Qiita)

URL：

開発の背景から解説しています。

## 動画

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
  - AWS(EC2, VPC, Route53, ACM, ALB)
  - GitHub Actions(CI/CD)

## インフラ構成図
![infra (1)](https://github.com/user-attachments/assets/1096ce46-a96b-4117-b957-7d2af11be465)
※ロードバランサーでEC2を2つ設置しましたが、GitHub Actionsでコンテナを起動できているのは一方のみです。