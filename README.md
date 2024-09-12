# 紙データの照合アプリ「OCR Check」
![トップページ](https://github.com/user-attachments/assets/2f007153-77e6-4e00-afa4-6814d645da81)

## 概要
![わたしの仕事](https://github.com/user-attachments/assets/cb20697f-64f1-4fbf-9b29-69f567e5290e)
私は認知機能検査の採点および入力（手書き）を行う仕事をしています。

その仕事において、紙データとエクセルデータの照合に時間がかかる問題を抱えていました。

そこで、OCR技術を活用して、照合作業を効率化するアプリ「OCR Check」を開発しました。

## どんな課題を解決するのか？
![現状どのように照合しているか](https://github.com/user-attachments/assets/9809bee3-86a5-4351-8682-13e17a98fafa)
①検査用紙のコピーと②エクセルを印刷した紙を2人体制でチェックして不一致を見つけたら修正していました。  
  
![現状どのような課題がある？](https://github.com/user-attachments/assets/33d999a6-8f9d-46e4-93c5-5127b3148408)
①時間が取られて他の業務ができない  
②「ミスできない」など心理的プレッシャーが大きい  
という2つの課題がありました。

![アプリを使うとどうなる？](https://github.com/user-attachments/assets/3b6876f1-1c29-4177-922c-713e706ce2c1)
OCR Checkを使うと、今まで2人合わせて1時間20分かかっていた作業が15分で完了します。  
また、チームメンバーの心理的負担を軽減することができます。

## 開発背景
1ヶ月あたり190人、合計およそ1,000人分のチェックを3人で分担していたため、1人あたりの量も多く、1つ1つ目視で確認するのが大変でした。

不一致の見落としがないように注意深く確認していましたが、それでも200件のうち3件ほど見落としがありました。

**「どんなに注意してやっても、人力だと見落としが発生してしまう。自動化すれば見落としを防げるし、効率化できるのはないか？」**
と考え、照合作業を自動化する方法を調べ始めました。

OCR Checkを作ろうと考えた背景やユーザーインタビューの内容は、こちらの記事で詳しく解説しています。

[OCR Check開発の背景・ユーザーインタビュー・技術を選んだ理由](https://qiita.com/naota7118/private/1790c44202a52e992170)

### 具体的にどのようなデータを照合するのか？
具体的には、PDFから得点データを抽出し、Excelデータと一致しているかを確認します。
![OCR Check説明資料](https://github.com/user-attachments/assets/ab58a5cb-d9d7-4f07-a7ec-a0c19f1a6678)

具体的には、PDFから得点データを抽出し、Excelデータと一致しているかを確認します。

## 説明動画
動画で実際にどのように照合が行われているか説明しています。  
下の画像をクリックしていただくと、YouTube動画が再生されます。  
※1.25倍速をおすすめします。

[![OCRCheckの説明動画](https://github.com/user-attachments/assets/254085b1-15fd-4fa5-a239-1f11d59dfcc9)](https://www.youtube.com/watch?v=8EbsyVoQ1HA)

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
![ocrcheck_infra](https://github.com/user-attachments/assets/403c1d0d-68b3-44a7-91a1-ebcc806b55f4)