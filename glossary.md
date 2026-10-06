# 用語集 / Glossary

Keep terminology consistent across `src/<target>.md` and `figures/*.<target>.txt`.
Change an entry here first, then search and replace in both places.

Style (ja): です・ます調. Half-width alphanumerics, no space between Japanese and Latin text (e.g. `4D.Vector型`).
Full-width `（）` and `：` in prose. First occurrence of a technical term: 日本語（English）.

## 4D terms (from the official 4D Japanese documentation)

| English | 日本語 | Notes |
|---|---|---|
| entity / entity selection | エンティティ / エンティティセレクション | |
| datastore | データストア | |
| dataclass | データクラス | |
| attribute | 属性 | |
| computed attribute | 計算属性 | |
| collection | コレクション | |
| object | オブジェクト | |
| method | メソッド | |
| project method | プロジェクトメソッド | |
| function | 関数 | |
| class | クラス | |
| parameter | 引数 | |
| form | フォーム | |
| form object | フォームオブジェクト | |
| list box | リストボックス | |
| web area | Webエリア | |
| 4D Web Server | 4D Webサーバー | |
| worker | ワーカー | |
| process | プロセス | |
| query | クエリ | |
| formula | フォーミュラ | |
| component | コンポーネント | |
| alias attribute | エイリアス属性 | |
| singleton function | シングルトン関数 | |
| data model class function | データモデルクラス関数 | |
| datastore class function | データストアクラス関数 | |
| exposed (function) | 公開された（exposed） | First occurrence with English |
| privilege | 権限 | developer.4d.com/docs/ja/ORDA/privileges |
| role | ロール | |
| permission | パーミッション | |
| permission action | 許諾アクション | Section "Permission actions" |
| resource | リソース | |
| database method | データベースメソッド | |
| Structure Settings | ストラクチャー設定 | |
| Settings → Web → Web Features | 設定 → Web → Web機能 | UI path; screenshot fig-03 is English |
| web user session | Webユーザーセッション | |
| 4D Client license | 4Dクライアントライセンス | |
| primary key | プライマリーキー | |
| record / table | レコード / テーブル | |

## Document-specific terms

| English | 日本語 | Notes |
|---|---|---|
| Force Login (mode) | 強制ログイン（モード） | Official 4D docs (REST/authUsers); first occurrence 強制ログイン（Force Login） |
| guest session | ゲストセッション | 「ゲスト」Webユーザーセッション |
| descriptive REST requests | 記述的RESTリクエスト | Official 4D docs |
| credentials | 資格情報 | |
| authenticate / authentication | 認証する / 認証 | |
| authorization | 認可 | |
| sign in / log in / log out | サインイン / ログイン / ログアウト | Kept as in source |
| promote (itself) | 昇格（させる） | The action name `promote` stays in English |
| locking privilege ("none") | ロック用の権限 | |
| legacy | レガシー（な） | |
| secure-by-default | セキュア・バイ・デフォルト | |
| deny-all approach | すべてを拒否するアプローチ | |
| Security Warning | セキュリティ上の警告 | Callout label |
| Important / Important Note(s) | 重要 / 重要な注意点 | Callout label |
| Method / URL / Body (request) | メソッド / URL / ボディ | Postman request fields |
| What happens | 処理の流れ | |
| heavy client | ヘビークライアント | |
| "Activate REST authentication through ds.authentify() function" | kept in English | Button label matches the English screenshot (fig-03) |

## Proper nouns in examples

| English | 日本語 | Notes |
|---|---|---|
| Qodly, Qodly Renderer, Postman | (unchanged) | Product names |
| Company (dataclass), User (dataclass/table) | (unchanged) | Code identifiers |
| AccessTOCOMPANY, Admin, Administrator, none, RestAccess, userAccess | (unchanged) | Privilege/group names in code |
| Innovatech, Rabat, Marrakech, john | (unchanged) | Sample data; may be localised in Phase 4 |
