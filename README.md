# OCR Check

現在の仕事で、紙データとエクセルデータの照合で時間がかかる問題を抱えていました。  

OCR技術を活用して、照合作業の効率化およびミス防止のためのアプリです。

## 解説記事(Qiita)
OCRアプリを作ろうと考えた背景やユーザーインタビューの内容は、こちらの記事で詳しく解説しています。

[OCR Check開発の背景・ユーザーインタビュー・技術を選んだ理由・進捗管理・アウトプット](https://qiita.com/naota7118/private/1790c44202a52e992170)

また、エンジニアになりたい理由についてはこちらの記事で詳しく書いております。

[【志望動機】なぜエンジニアになりたいのか？](https://qiita.com/naota7118/private/0a95c145ecaec38e6ee9)

## 動画
https://github.com/user-attachments/assets/0368b8a5-8ccf-4587-bec9-d35a3c51dd34

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

※EC2を2つ設置しましたが、GitHub Actionsでコンテナを起動できているのは一方のみです。