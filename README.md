# 紙データの照合アプリ「OCR Check」
![トップページ](https://github.com/user-attachments/assets/2f007153-77e6-4e00-afa4-6814d645da81)

## 概要
わたしは治験の検査員を行っています。
![わたしの仕事](https://github.com/user-attachments/assets/cb20697f-64f1-4fbf-9b29-69f567e5290e)
認知機能検査の採点および入力（手書き）を行う業務があります。

その業務において、紙データとエクセルデータの照合に時間がかかる問題を抱えていました。

そこで、OCR技術を活用して、照合作業を効率化するアプリ「OCR Check」を開発しました。

## どんな課題を解決するのか？
現状で以下3つの課題があります。
![現状どのような課題がある？](https://github.com/user-attachments/assets/e800f53c-eda7-40ff-b7dd-8cba4e33888c)
 
1ヶ月あたり190人、5ヶ月で合計およそ1,000人分のデータを2人体制でチェックしていました。  

不一致の見落としがないように注意深く確認していましたが、それでもひと月200件のうち3〜4件ほど見落としがありました。

**「どんなに注意してやっても、人力だと見落としが発生してしまう。自動化すれば見落としを防げるし、効率化できるのはないか？」**
と考え、照合作業を自動化する方法を調べ始めました。

開発を始める前に行った事前ヒアリングやユーザーインタビューの内容は、こちらの記事で詳しく解説しています。

[OCR Check事前ヒアリング・ユーザーインタビュー・技術を選んだ理由](https://qiita.com/naota7118/private/1790c44202a52e992170)

## 業務の流れ
業務の流れを順を追って説明します。
![検査実施からエクセル入力までの流れ](https://github.com/user-attachments/assets/c141e257-d00e-4ce0-9e14-14e9557bab6b)
まず、被験者様と検査者によって検査が行われます。  
検査が終わった時点では、得点は記入されていません。  

いきなり検査用紙に得点を記入してしまうと、得点が間違っていた場合に何度も修正した跡が残ってしまうため、検査用紙を印刷します。  
検査用紙のコピーと原本が採点チームに渡されます。  

採点業務は、まず1人目が採点を行い、検査用紙のコピーに得点を記入します。  
その後、2人目と3人目が採点を行います。  
3人の得点が一致したらエクセル表に得点を入力します。

![検査用紙の原本に得点を記入するまでの流れ](https://github.com/user-attachments/assets/7fe21aa8-f6d9-4cc8-9f47-ae2d1ada0dcf)
その後、検査用紙コピーに記入された得点とエクセルに入力された得点が一致しているかを確認し、一致していたら原本に転記します。

![なぜエクセルに入力して照合するのか？](https://github.com/user-attachments/assets/7c7d0b70-c63f-4dbd-a81d-897bc085edff)
「エクセルに入力して検査用紙コピーと照合する」手順を踏む理由は、原本の正確性を担保するためです。
  
![現状どのように照合しているか](https://github.com/user-attachments/assets/2837a912-bdbc-4f8f-b2c7-d039aa0219ee)
現状では、①検査用紙のコピーと②エクセルを印刷した紙を見比べて、一致しているか確認しています。  
一致していなかったら間違っているほうの得点を修正します。
  
![エクセル得点表を印刷した紙のサンプル](https://github.com/user-attachments/assets/8b1e7fee-3792-4cf2-9ae9-719c68362f21)
このように、一致していたらマーカーやチェックを入れて照合の結果を残していました。  
  
## アプリを使うとどう変わるか？
![OCR Checkで照合作業はどう変わる？](https://github.com/user-attachments/assets/502170ff-b6b0-4cf8-8de1-3e3202014e1f)
OCR Checkを使うと、今まで2人合わせて1時間20分かかっていた作業が15分で完了します。  
  
![OCR Checkを使う３つのメリット](https://github.com/user-attachments/assets/80d94fb3-517c-4a86-9aef-3262cd45305d)
照合作業が効率化されるだけでなく、ヒューマンエラーの防止や検査員の業務パフォーマンス向上が期待できます。

### 具体的にどのようなデータを照合するのか？
具体的には、PDFから得点データを抽出し、Excelデータと一致しているかを確認します。
![OCR Check説明資料](https://github.com/user-attachments/assets/ab58a5cb-d9d7-4f07-a7ec-a0c19f1a6678)

具体的には、PDFから得点データを抽出し、Excelデータと一致しているかを確認します。

## 説明動画
動画で実際にどのように照合が行われているか説明しています。  
下の画像をクリックしていただくと、YouTube動画が再生されます。  
※1.25倍速をおすすめします。

[![OCRCheckの説明動画](https://github.com/user-attachments/assets/254085b1-15fd-4fa5-a239-1f11d59dfcc9)](https://www.youtube.com/watch?v=8EbsyVoQ1HA)

## 工夫したところ
![検査用紙から得点データを抽出する流れ](https://github.com/user-attachments/assets/5c62996a-58c8-4ce6-acc2-6bbaeac05bb7)
①検査用紙のテキストデータ(txtファイル)から得点を抽出する処理を考え実装しました。
  
![PDFデータとExcelデータを照合する流れ](https://github.com/user-attachments/assets/32e39a9d-219f-4d50-af67-1a12d42014da)
②PDFデータ（検査用紙データ）とエクセルの得点データを照合する処理を考え実装しました。

③職場の上司にヒアリングしてから開発を始め、ユーザーインタビューを行い改善しています。

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
    一致しなかった項目に色をつける処理を実装しました。
- インフラ
  - Docker
  - AWS(EC2, VPC, Route53, ACM, ALB, WAF)
  - GitHub Actions CI/CDを自動化
- ライブラリ
  - google/apis/drive_v3  
    PDFからテキストデータを抽出するために使いました。  
    具体的には、PDFをGoogleドキュメント形式に変換し、Googleドキュメントからテキストファイルを出力することで、テキスト部分のみ抽出しています。
  - google/api_client/client_secrets  
    Google Drive APIのOCRを活用するにはGoogle認証を通す必要がありました。
  - roo  
    フォーム送信したエクセルデータから照合に必要な得点データを取得するために使いました。指定した列の値のみ配列に格納するようにしました。
  - high_voltage  
    トップページを表示するために使いました。静的なページをコントローラを作らず表示できないか調べていて見つけました。

## インフラ構成図
![ocrcheck_infra](https://github.com/user-attachments/assets/403c1d0d-68b3-44a7-91a1-ebcc806b55f4)