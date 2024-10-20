## テーブル定義書
テーブル：original_data
| カラム名       | データ型        | NULL | キー      | 初期値 | AUTO INCREMENT |
| ---------- | ----------- | ---- | ------- | --- | -------------- |
| id         | bigint(20)  |      | PRIMARY |     | YES            |
| subject_id | bigint(20)  |      | INDEX   |     |                |
| start_time | time        |      |         |     |                |
| end_time   | time        |      |         |     |                |
| inspector  | varchar(50) |      |         |     |                |
- ユニークキー制約：subject_idカラムに対して設定

テーブル：excel_scores
| カラム名       | データ型        | NULL | キー      | 初期値 | AUTO INCREMENT |
| ---------- | ----------- | ---- | ------- | --- | -------------- |
| id         | bigint(20)  |      | PRIMARY |     | YES            |
| subject_id | bigint(20)  |      | INDEX   |     |                |
- ユニークキー制約：subject_idカラムに対して設定