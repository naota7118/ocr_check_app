## 1.一言サービスコンセプト
目視によるチェックでかかる工数を減らす

## 2.誰のどんな課題を解決するのか？
- 原本とエクセルデータの照合に時間がかかる
- MoCAのID照合に38分かかった

## 3.なぜそれを解決したいのか？
- 業務を効率化するため
- 見落としをなくすため

## 4.どうやって解決するのか？
- 原本をスキャンして画像orPDFに変換
- OCR APIで画像からIDを抽出
- 原本とエクセルデータを照合
- 不一致を検出して表示

## 5.機能要件
- OCR APIによる画像からテキスト抽出
- 原本データとエクセルデータを照合
- ユーザーログイン(余裕があれば)

## 6.非機能要件
- GitHubへプッシュ時に静的解析で自動チェック
- CSRF対策
- SQLインジェクション対策
- XSS対策