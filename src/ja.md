# 4DにおけるREST認証の強制ログイン

著者：Abir HSAINI（4D Inc. テクニカルサービスエンジニア）

テクニカルノート 25-10

## 概要

4Dの「強制ログイン（Force Login）」機能は、保護された操作を実行する前にユーザーのサインインを必須とすることで、RESTサービスおよびQodlyアプリケーションへのアクセスを保護します。最初に接続が確立されると、権限もライセンスも割り当てられていないゲストセッションが作成され、有効なログイン資格情報が提供されるまでその状態が続きます。

この機能はセキュリティを強化するだけでなく、RESTおよびQodlyアクセスのライセンス管理も改善します。また、詳細なロールと権限を利用して、ユーザーのアクセス許可を厳密に制御できるようになります。

本ドキュメントでは、従来の認証設定から新しい「強制ログイン」機能へ移行する方法、authentify関数の仕組みとライセンスの割り当て方、そしてroles.jsonファイルでアクセス権を定義する方法を説明します。サインイン、データの参照、新規レコードの作成を行うRESTコールの具体例を通じて、4DのRESTサービスへの安全で適切に管理されたアクセスを実現する方法を紹介します。

## はじめに

現代のWebアーキテクチャーにおいて、**REST**サービスは、アプリケーションのロジックやデータをさまざまなクライアント（Webフロントエンド、モバイルアプリ、外部システム）に公開するうえで重要な役割を担っています。しかし、このようなアクセスのしやすさには、セキュリティという最重要の課題が伴います。4Dでは、「強制ログイン」モードがRESTエンドポイントを保護するための、より堅牢できめ細かな仕組みとなっており、適切な権限を持つ認証済みセッションだけが機密性の高い操作を実行できるようにします。

4D 20 R6以降、新規プロジェクトでは強制ログインがデフォルトのREST認証モードになりました。「On REST Authentication」データベースメソッドに依存するといった、従来の「レガシー」な方法は非推奨となっています。

本テクニカルノートでは、レガシーなREST設定から強制ログインモデルへ移行する手順を紹介します。サインインのワークフローの仕組み、セッションとライセンスの管理方法、そしてroles.jsonファイルを使ったアクセス権の定義方法を説明します。また、データの参照・作成・更新・保護を行う実践的なRESTコールの例を示し、RESTサービスへの安全で整理されたアクセスを実現する方法を紹介します。

## 新規プロジェクトと既存プロジェクト

### 新規プロジェクトの強制ログインモード（v20 R6以降）

バージョン20 R6以降、4Dは強制ログインモードによって、新規プロジェクトに「セキュア・バイ・デフォルト」のアプローチを採用しています。この仕組みにより、保護されたREST操作はすべて、実行前に適切な認証が必要になります。

4D v20 R6以降で新規プロジェクトを作成すると、システムは自動的に次の処理を行います：

- Sourcesフォルダーにroles.jsonファイルを生成する
- forceLogin属性をtrueに設定する
- デフォルトで"none"権限を適用し、REST API全体へのアクセスを拒否する

このデフォルト設定は、すべてを拒否するアプローチを採用することでデータセキュリティのベストプラクティスに従っています。開発者は、アクセスを開放した状態で運用するのではなく、必要に応じて明示的にパーミッションを付与する必要があります。

![](fig-01)

次の図は、roles.jsonの内容をQodlyでよりわかりやすく表示したものです。

![](fig-02)

### 既存プロジェクトの強制ログインモードへの移行

バージョン20 R6より前に作成されたプロジェクトや、レガシーなREST認証方式を使い続けているプロジェクトで新しいセキュリティモデルを採用するには、移行が必要です。4Dには、簡単に実行できる自動変換の仕組みが用意されています。

既存のプロジェクトを移行するには：

1. ストラクチャー設定 → Web → Web機能 を開きます
2. 「ds.authentify() 関数を通してのREST認証を有効化」ボタンをクリックします

![](fig-03)

変換の際、4Dは次の処理を実行します：

- **レガシーなパーミッションの削除**：従来のREST設定でRESTアクセスを許可されていたユーザーグループを削除します
- **レガシー認証の無効化**：**On REST Authentication**データベースメソッドをシステムフォルダーに移動します（無効化された状態）
- **セキュリティ設定の作成**：Sourcesフォルダーに**roles.json**ファイルを生成し（存在しない場合）、forceLogin: trueとデフォルトの"none"権限を設定します

> **重要**：**roles.json**ファイルを編集して"forceLogin": trueを追加するだけでは、データベースの更新には**不十分**です。移行を正しく完了するには、**「ds.authentify() 関数を通してのREST認証を有効化」**ボタンを**必ず**クリックしてください。

## 強制ログインの仕組み

4Dの強制ログインの仕組みは、3つのステップからなる認証ワークフローに従っています。これにより、REST APIへの安全なアクセスを確保しつつ、ライセンスの消費を最適化します。

### ステップ1：最初のRESTリクエスト - ゲストセッションの作成

強制ログインが設定された4Dアプリケーションに、リモートの4Dクライアントが**最初のRESTリクエスト**を送信すると：

- **「ゲスト」Webユーザーセッション**がデフォルトで自動的に作成されます
- このセッションには**権限がなく**、データリクエストを実行する**権利もありません**
- ゲストセッションでは**記述的RESTリクエスト**のみが許可されます

#### 記述的RESTリクエスト：

ゲストセッションは、認証やライセンスを必要とせずに、次の種類の記述的RESTリクエストを処理できます：

- /rest/$catalogリクエスト（例：/rest/$catalog/$all）- 利用可能なデータクラスへのアクセスを提供します
- /rest/$catalog/authentify - ユーザーの認証に使用するデータストア関数です
- /rest/$getWebForm - Qodlyページをレンダリングします（ログインフォームの表示に便利です）

これらの記述的リクエストは、ライセンスを消費するWebユーザーセッションが開かれていない場合でも、常にサーバーで処理されます。これにより、リモートの4Dクライアントは、ライセンスを消費する前に、データクラスの数、データクラスのフィールド数、認証エンドポイントなどの情報を表示できます。

### ステップ2：authentify()関数の作成

認証を行うには、あらかじめ**authentify()関数**を**公開された（exposed）データストアクラス関数**として作成しておく必要があります。この関数は：

- ユーザーの資格情報を受け取り、検証します
- 資格情報が有効であれば、適切な権限を指定してSession.setPrivileges()を呼び出します
- 4Dライセンスが消費されるタイミングを制御します

> **重要**：RESTからアクセスできるようにするには、authentify()関数をデータストアクラスで明示的に公開する必要があります。

#### 実装方法

authentify()関数の実装方法は、レガシーな認証設定に応じて複数あります：

##### オプションA：オープンアクセス（認証不要）

以前の設定で、アクセスグループを定義せず、「On REST Authentication」データベースメソッドでリクエストのフィルタリングも行わずにRESTサーバーを公開していた場合は、REST API全体へのフルアクセスを付与することで同じ動作を再現できます：

```4d
Class extends DataStoreImplementation

exposed Function authentify() : Boolean
  return Session.setPrivileges("Administrator")
```

この例では：

- 資格情報は不要です（引数なし）
- 関数はただちに"Administrator"権限を付与します
- これにより、レガシーなオープン設定と同様に、REST APIへの無制限のアクセスが提供されます

> **セキュリティ上の警告**：この実装は安全ではないため推奨されません。すべてのデータと関数が、認証や認可のチェックなしに誰でもアクセスできる状態になります。

##### オプションB：4Dユーザーグループの利用（レガシーな読み取り/書き込みアクセス）

レガシーな設定で、REST APIへの読み取り/書き込みアクセス用に4Dユーザーのグループを定義していた場合は、新しいモードでも資格情報を確認し、定義されたグループのメンバーにフルアクセスを付与することで同じ動作を再現できます：

```4d
Class extends DataStoreImplementation

exposed Function authentify($identifier : Text; $pwd : Text) : Boolean
  If ($identifier#"")
    If (Validate password($identifier; $pwd))
      If (User in group($identifier; "RestAccess"))
        return Session.setPrivileges("Administrator")
      End if
    End if
  End if
```

この例では：

- 関数はValidate password()を使ってユーザーのパスワードを検証します。
- ユーザーが"RestAccess"グループ（以前にストラクチャー設定で定義したグループ）に属しているかどうかを確認します。
- 両方の条件を満たす場合、"Administrator"権限を付与します。
- この制限により、悪意のある接続からデータアクセスと関数を保護します。
- 許可された接続はすべて同じ権利を持ちます。

##### オプションC：独自のユーザー管理システム（レガシーな「On REST Authentication」メソッド）

以前、**「On REST Authentication」**データベースメソッドを使って独自のユーザー管理システムで資格情報を確認していた場合は、そのロジックをauthentify()関数に移行できます。

レガシーな「On REST Authentication」メソッド：

```4d
#DECLARE($identifier : Text; $pwd : Text) : Boolean

If ($identifier#"")
  var $user : cs.UserEntity:=ds.User.query("identifier = :1"; $identifier).first()
  If ($user#Null)
    If (Verify password hash($pwd; $user.pwd))
      return True
    End if
  End if
End if
```

置き換え後の「ds.authentify()」関数：

```4d
Class extends DataStoreImplementation

exposed Function authentify($identifier : Text; $pwd : Text) : Boolean
  If ($identifier#"")
    var $user : cs.UserEntity:=ds.User.query("identifier = :1"; $identifier).first()
    If ($user#Null)
      If (Verify password hash($pwd; $user.pwd))
        return Session.setPrivileges("Administrator")
      End if
    End if
  End if
```

この独自認証を機能させるには、開発者がroles.jsonファイルに**"userAccess"**という新しい権限を作成し、次のように設定する必要があります：

- Userテーブルへの**読み取りアクセス**を付与する
- **authentify**関数を**promote**リストに追加する

> **セキュリティ上の警告：**roles.jsonで、ゲストセッションにUserテーブルへの読み取りアクセスを単純に付与してはいけません。これはよくある間違いで、機密性の高いユーザーデータ（パスワードハッシュを含む）が未認証のユーザーに公開されてしまいます。代わりに**promote**の仕組みを使えば、一般のゲストアクセスに公開することなく、認証処理中のauthentify関数だけがUserテーブルにアクセスできるようになります。

この設定が必要なのは、ゲストセッションが資格情報を検証し、authentify関数を通じて自身を昇格させるために、Userテーブルへのアクセス許可が必要だからです。この設定がないと、認証は失敗します。

この例では：

- ユーザーの資格情報は独自のUserデータクラスに保存されています
- 関数はUserテーブルにクエリを実行し、識別子でユーザーを検索します
- 保存されているハッシュとパスワードハッシュを照合します
- 検証に成功すると、"Administrator"権限を付与します
- 前のオプションと同様に、許可された接続はすべて同じ権利を持ちます
- データと関数へのアクセス制限は、コード内で別途実装する必要があります

認証の方式（4Dの内部パスワード、Office 365によるOAuth2、Google認証、LDAP、独自のユーザーテーブルなど）にかかわらず、**すべての** **認証はds.authentify()関数を経由しなければなりません**。

### ステップ3：認証リクエスト

クライアントはサーバーに認証リクエストを送信します：

```http
POST /rest/$catalog/authentify
```

このリクエストには、ユーザーの資格情報（ユーザー名とパスワード）が含まれます。この段階では：

- 基本的なログインフォームだけが必要です（データアクセスは不要）
- リクエストは既存のゲストセッション内で処理されます

## RESTのライセンス消費

4Dの強制ログインモードでは、RESTセッションのライセンス管理に新しいアプローチが導入されています。ライセンスはセッションの作成時ではなく、権限が割り当てられたときにのみ消費されるため、リソースの割り当てを正確に制御できます。

### ゲストセッション - ライセンス不要

クライアントが新しいREST接続を開始すると：

- ゲストWebユーザーセッションが自動的に作成されます
- この段階では4Dライセンスは消費されません
- このゲストWebユーザーセッションには権限がまったくないため、データにアクセスすることもコードを実行することもできません
- このゲストWebユーザーセッションは、ライセンスなしで記述的RESTリクエストを処理できます
- 複数のゲストセッションが同時に存在しても、ライセンスには影響しません

### ライセンス消費のきっかけ

このゲストWebユーザーセッションに権限を割り当てる唯一の方法は、ds.authentify()を実行し、その中でSession.setPrivileges()を実行することです。

4Dクライアントライセンスは、Session.setPrivileges()関数が実行された**時点で（そしてその時にのみ）**消費されます。これは、認証処理の次のタイミングで発生します：

1. クライアントが/rest/$catalog/authentifyエンドポイントを呼び出します
2. authentify()関数がアクセスを試みたユーザーを識別・確認します
3. authentify()関数が適切な権限を指定してSession.setPrivileges()を呼び出します
4. まさにこの瞬間に、サーバー上で**4Dクライアントライセンスが消費されます**

## ライセンス管理のライフサイクル

- **動的な割り当て**：ライセンスは、ユーザーからの最初のHTTP/RESTリクエストの際に（具体的には、認証中にSession.setPrivileges()が呼び出されたときに）動的に割り当てられます。開発者がヘビークライアント（クライアント/サーバーのデスクトップ）で接続しても、Webブラウザークライアントで接続しても、同じライセンス（4Dクライアント）が消費されます。
- **ライセンスの紐付け**：一度割り当てられたライセンスは、そのユーザーセッションが続く間、セッションに紐付けられたままになります。ライセンスはその特定のセッションに結び付けられ、ほかのユーザーに譲渡したり共有したりすることはできません。
- **ライセンスの解放：**ライセンスは、次の条件で自動的に解放されます：
    - セッションのタイムアウト：セッションのタイムアウト期間（デフォルトは最短1時間）中にRESTリクエストを受信しなかった場合、ライセンスは自動的に解放されます
    - サーバーの再起動：4D Serverを再起動すると、ライセンスはただちに解放されます
    - ユーザーのログアウト：エンドユーザーがQodlyページのインターフェース（Qodly Rendererを使用）から「ログアウト」アクションを実行した場合も、セッションのライセンスは解放されます。
- **ライセンスの共有不可：**1つのRESTライセンスを複数のユーザーが同時に使用することはできません。ライセンスを持つセッションごとに、利用可能なライセンスプールから専用のライセンスが1つ必要です。

## ロールと権限（roles.json）

ORDAのセキュリティアーキテクチャーは、権限、許諾アクション（read、createなど）、およびリソースの概念に基づいています。WebユーザーまたはRESTユーザーがログインすると、そのセッションには関連する権限が自動的に読み込まれます。権限は、**session.setPrivileges()**関数によってセッションに割り当てられます。

セッション内で送信されるユーザーリクエストはすべて、プロジェクトの**roles.json**ファイルで定義された権限に対して評価されます。適切なアクセス権を持たないアクションをユーザーが実行しようとすると、権限エラーが生成されます。また、属性に対する読み取り（read）パーミッションがない場合は、その属性は送信されません。

プロジェクト内の次のリソースに、特定の許諾アクションを割り当てることができます：

- データストア
- データクラス
- 属性（計算属性とエイリアス属性を含む）
- データモデルクラス関数
- シングルトン関数

セッション内でリソースにアクセスするたびに（アクセスの方法にかかわらず）、4Dはセッションが適切なパーミッションを持っているかを確認し、許可されていない場合はアクセスを拒否します。

### 許諾アクション

利用できるアクションは、対象となるリソースによって異なります：

| アクション | データストア | データクラス | 属性 | データモデル関数またはシングルトン関数 |
|---|---|---|---|---|
| **create** | 任意のデータクラスでエンティティを作成 | このデータクラスでエンティティを作成 | この属性に許可されたデフォルト値とは異なる値を持つエンティティを作成（エイリアス属性では無視されます）。 | n/a |
| **read** | 任意のデータクラスの属性を読み取り | このデータクラスの属性を読み取り | この属性の内容を読み取り | n/a |
| **update** | 任意のデータクラスの属性を更新。 | このデータクラスの属性を更新。 | この属性の内容を更新（エイリアス属性では無視されます）。 | n/a |
| **drop** | 任意のデータクラスのデータを削除。 | このデータクラスのデータを削除。 | この属性のnullでない値を削除（エイリアス属性と計算属性を除く）。 | n/a |
| **execute** | プロジェクトの任意の関数を実行（データストア、データクラス、エンティティセレクション、エンティティ、シングルトン） | データクラスの任意の関数を実行。データクラス関数、エンティティ関数、エンティティセレクション関数は、データクラス関数として扱われます | n/a | この関数を実行 |
| **promote** | n/a | n/a | n/a | 関数の実行中に、指定した権限を関連付けます。権限は一時的に追加され、関数の実行終了時に削除されます。セキュリティ上、権限が追加されるのはセッション全体ではなく、その関数を実行しているプロセスだけです。 |

> 重要：RESTの強制ログインモードでは、パーミッションの設定にかかわらず、authentify()関数は常にゲストユーザーが実行できます。

### roles.jsonファイル

プロジェクトを作成すると、デフォルトのroles.jsonファイルが次の場所に作成されます：**&lt;project folder&gt;/Project/Sources/**

最高レベルのセキュリティを確保するため、データストアのすべてのパーミッションに"none"権限が割り当てられています。つまり、デフォルトではdsオブジェクト全体のデータアクセスが無効になっています。

> 重要：このロック用の権限を変更したり使用したりせず、WebリクエストやRESTリクエストで利用可能にしたい各リソースに個別のパーミッションを追加することを推奨します。

デフォルトのファイルの内容は次のとおりです：

```json
{
  "privileges": [
    {
      "privilege": "none",
      "includes": []
    }
  ],
  "roles": [],
  "permissions": {
    "allowed": [
      {
        "applyTo": "ds",
        "type": "datastore",
        "read": ["none"],
        "create": ["none"],
        "update": ["none"],
        "drop": ["none"],
        "execute": ["none"],
        "promote": ["none"]
      }
    ]
  },
  "forceLogin": true
}
```

roles.jsonファイルの構文は次のとおりです：

| プロパティ | 型 | 必須 | 説明 |
|---|---|---|---|
| **privileges** | privilegeオブジェクトのCollection | ✅ | 定義された権限のリスト |
| **[].privilege** | Text | | 権限名 |
| **[].includes** | StringのCollection | | 内包する権限名のリスト |
| **roles** | roleオブジェクトのCollection | | 定義されたロールのリスト |
| **[].role** | Text | | ロール名 |
| **[].privileges** | StringのCollection | | 内包する権限名のリスト |
| **permissions** | Object | ✅ | 許可されたアクションのリスト |
| **allowed** | permissionオブジェクトのCollection | | 許可されたパーミッションのリスト |
| **[].applyTo** | Text | ✅ | 対象リソース名 |
| **[].type** | Text | ✅ | リソースの種類："datastore"、"dataclass"、"attribute"、"method"、"singletonMethod"、"singleton" |
| **[].read**, **[].create**, **[].update**, **[].drop**, **[].execute**, **[].promote** | StringのCollection | | 権限名のリスト |
| **forceLogin** | Boolean | | *強制ログイン*モードを有効にする |

> 重要な注意点："WebAdmin"という権限名はアプリケーション用に予約されています。独自の権限にこの名前を使用することは推奨されません。

roles.jsonファイルを手作業で編集する代わりに、**Qodly**の**ロールと権限（Roles and Privileges）**ページを使用することを推奨します。このインターフェースを使えば、より直感的かつ安全にロールを定義し、権限を割り当て、アプリケーション全体で一貫したアクセス制御を維持できます。

![](fig-04)

### エラー処理

roles.jsonファイルは、4Dの起動時に解析されます。このファイルの変更を反映するには、アプリケーションを再起動する必要があります。

roles.jsonファイルの解析中にエラーが発生した場合、4Dはプロジェクトを読み込みますが、グローバルなアクセス保護を無効にします。これにより、開発者はファイルにアクセスしてエラーを修正できます。デフォルトでは、プロジェクトのLogsフォルダーにRoles_Errors.jsonという名前のエラーファイルが生成され、エラーのある行が記述されます。このファイルは、roles.jsonファイルのエラーがなくなると自動的に削除されます。

起動時に、LogsフォルダーにRoles_Errors.jsonファイルが存在するかどうかを確認することを推奨します。このファイルが存在する場合は、解析エラーが発生しており、アクセスが制限されていないことを意味します。

### 設定のベストプラクティス

推奨されるのは、"none"権限によってすべてのデータアクセスをデフォルトでロックしたままにし、承認されたセッションに対して管理された部分だけを開放するようにroles.jsonファイルを設定することです。

```json
{
  "privileges": [
    {
      "privilege": "none",
      "includes": []
    }
  ],
  "roles": [],
  "permissions": {
    "allowed": [
      {
        "applyTo": "ds",
        "type": "datastore",
        "read": ["none"],
        "create": ["none"],
        "update": ["none"],
        "drop": ["none"],
        "execute": ["none"],
        "promote": ["none"]
      },
      {
        "applyTo": "ds.loginAs",
        "type": "method",
        "execute": ["guest"]
      },
      {
        "applyTo": "ds.hasPrivilege",
        "type": "method",
        "execute": ["guest"]
      }
    ]
  },
  "forceLogin": true
}
```

この設定では、データストアはデフォルトでロックされていますが、認証に関連する特定のメソッドにはゲストセッションからアクセスできます。

## デモ

このセクションでは、最初の認証からデータ操作まで、強制ログインモードが設定された4DのREST APIとやり取りする方法を実践的な例で紹介します。

### 4Dユーザーグループによる認証

強制ログインが有効なREST APIを扱う最初のステップは、カタログエンドポイントを通じてauthentify()関数を呼び出し、ユーザーを認証することです。

**authentify()関数：**

![](fig-05)

この例ではPostmanを使ってリクエストを送信します。リクエストは次のように設定します：

**メソッド：** POST

**URL：** http://localhost/rest/$catalog/authentify

**ボディ：**

- **raw**形式を選択します
- ドロップダウンから**JSON**を選択します
- 次のJSONを入力します：

```json
[{
  "name": "john ",
  "password": "1234"
}]
```

![](fig-06)

**処理の流れ：**

1. サーバーが資格情報を受け取ります
2. authentify()関数が識別子とパスワードを検証します
3. 有効であれば、Session.setPrivileges()が呼び出されて権限が割り当てられます
4. 4Dライセンスが消費されます
5. レスポンスヘッダーでセッションcookieが返されます
6. **Postmanがこのセッションcookieを自動的に取得して保存します**
7. セッションが認証済みになり、保護されたリソースにアクセスできるようになります

### roles.jsonの設定

以下の例では、次のroles.json設定を使用します：

```json
{
     "forceLogin": true,
     "permissions": {
          "allowed": [
               {
                    "applyTo": "Company",
                    "type": "dataclass",
                    "read": [
                         "AccessTOCOMPANY"
                    ],
                    "create": [
                         "AccessTOCOMPANY"
                    ],
                    "drop": [
                         "AccessTOCOMPANY"
                    ]
               },
               {
                    "applyTo": "Company.getCompanyByName",
                    "type": "method",
                    "execute": [
                         "AccessTOCOMPANY"
                    ],
                    "promote": [
                         "AccessTOCOMPANY"
                    ]
               },
               {
                    "applyTo": "ds",
                    "type": "datastore",
                    "read": [
                         "none"
                    ],
                    "create": [
                         "none"
                    ],
                    "update": [
                         "none"
                    ],
                    "drop": [
                         "none"
                    ],
                    "execute": [
                         "none"
                    ]
               },
               {
                    "applyTo": "ds.hasPrivilege",
                    "type": "method",
                    "execute": [
                         "Admin"
                    ]
               },
               {
                    "applyTo": "ds.getPrivileges",
                    "type": "method",
                    "execute": [
                         "Admin"
                    ]
               }
          ]
     },
     "privileges": [
          {
               "privilege": "AccessTOCOMPANY",
               "includes": []
          },
          {
               "privilege": "none",
               "includes": []
          },
          {
               "privilege": "Admin",
               "includes": [
                    "AccessTOCOMPANY"
               ]
          }
     ],
     "roles": []
}
```

### 設定の解説

#### 定義されている権限

- **AccessTOCOMPANY**：Companyデータクラスへのアクセスを付与する基本的な権限
- **none**：すべてのアクセスを拒否する、デフォルトのロック用権限
- **Admin**：AccessTOCOMPANY権限を内包する管理者用の権限

#### パーミッションの構成

**データストアレベル（ds）：**

- すべての操作（read、create、update、drop、execute）が"none"権限でロックされています。つまり、デフォルトではデータアクセスは一切許可されません

**Companyデータクラス：**

- read："AccessTOCOMPANY"権限が必要です
- create："AccessTOCOMPANY"権限が必要です
- drop："AccessTOCOMPANY"権限が必要です
- update：明示的に定義されていないため、データストアの設定を継承します（拒否）

**Company.getCompanyByName()メソッド：**

- **execute**："AccessTOCOMPANY"権限が必要です
- **promote**：実行中は"AccessTOCOMPANY"権限に一時的に昇格されます

**管理用メソッド：**

- ds.hasPrivilege()：実行には"Admin"権限が必要です
- ds.getPrivileges()：実行には"Admin"権限が必要です

**権限の階層**

- "Admin"権限は"AccessTOCOMPANY"権限を内包しています。つまり：
    - "Admin"権限を持つユーザーは、"AccessTOCOMPANY"が提供するすべてのものに自動的にアクセスできます
    - "AccessTOCOMPANY"権限だけを持つユーザーは、ds.hasPrivilege()やds.getPrivileges()などの管理者専用メソッドを実行できません

### 独自のデータストア関数の使用

この例を説明するため、**DataStoreImplementation**クラスに**hasPrivilege()**と**getPrivileges()**の2つのメソッドを作成し、**Admin**権限を持つユーザーだけに実行パーミッションを付与します。

![](fig-07)

#### ds.hasPrivilege()による権限の確認

リクエストは次のように設定します：

**メソッド：** POST

**URL：** http://localhost/rest/$catalog/hasPrivilege

**ボディ：** [“Admin”]

roles.jsonファイルでは、この関数は次のように設定されています：

```json
 {
            "applyTo": "ds.hasPrivilege",
            "type": "method",
            "execute": [
                 "Admin"
            ]
       },
```

![](fig-08)

認証済みのセッションは"Admin"権限を持っているため、このメソッドはtrueを返します。

#### ds.getPrivileges()によるセッションの全権限の取得

リクエストは次のように設定します：

**メソッド：** POST

**URL：** http://localhost/rest/$catalog/getPrivileges

roles.jsonファイルでは、この関数は次のように設定されています：

```json
{
            "applyTo": "ds.getPrivileges",
            "type": "method",
            "execute": [
                 "Admin"
            ]
       }
```

![](fig-09)

認証済みのセッションは"Admin"権限を持っているため、このメソッドは現在のセッションに割り当てられているすべての権限を返し、"Admin"とそれに内包される"AccessTOCOMPANY"権限の両方が表示されます。

#### Admin権限なしで管理用メソッドを呼び出した場合

必要な権限を持たないゲストユーザーがこれらのメソッドを実行しようとすると、リクエストは失敗し、次のエラーメッセージが返されます：

![](fig-10)

### 認証後のデータ取得

"Admin"権限（"AccessTOCOMPANY"を内包）で認証されると、セッションはCompanyデータクラスからデータを取得できるようになります。

#### 例1：すべての会社の取得

この例では、RESTリクエストを使って**Company**データクラスのすべてのレコードを取得する方法を示します。

**メソッド：** GET

**URL：** http://localhost/rest/Company

![](fig-11)

認証済みのセッションは、Companyデータクラスに対する**read**パーミッションを付与する"AccessTOCOMPANY"権限を持っているため、リクエストは成功します。

#### 例2：キーによる特定の会社の取得

この例では、RESTリクエストを使って、プライマリーキーで特定の**Company**エンティティを取得する方法を示します。

このリクエストは、**Company**データクラスでキー（ID）が**1**のレコードを対象とします。

**メソッド：** GET

**URL：** http://localhost/rest/Company(1)

![](fig-12)

認証済みのセッションは、**Company**データクラスの個々のレコードに対する読み取りパーミッションを付与する**AccessTOCOMPANY**権限を持っているため、リクエストは成功します。

#### 例3：クラス関数による会社のクエリ

標準のRESTクエリに加えて、公開されたデータクラス関数を呼び出してデータを取得することもできます。この例では、roles.jsonで**execute**と**promote**のパーミッションが設定されたCompany.getCompanyByName()メソッドの使い方を示します。

**Postmanでのリクエスト**

**メソッド：** POST

**URL：** http://localhost/rest/Company/getCompanyByName

**ボディ：**

```json
["Innovatech"]
```

**関数：**

この関数は、Companyデータクラスから、companyNameが渡された引数と一致するレコードを検索し、対応するコレクションを返します。

![](fig-13)

**結果：**

![](fig-14)

roles.jsonファイルでは、この関数は次のように設定されています：

```json
{"applyTo": "Company.getCompanyByName",
  "type": "method",
  "execute": [
    "AccessTOCOMPANY"
  ],
  "promote": [
    "AccessTOCOMPANY"
  ]}
```

- **execute**："AccessTOCOMPANY"権限を持つユーザーはこのメソッドを呼び出せます
- **promote**：関数の実行中は"AccessTOCOMPANY"権限に一時的に昇格されるため、通常は制限される可能性のある操作も実行できます

### 新しいCompanyレコードの作成

"Admin"権限で認証された後は、"AccessTOCOMPANY"権限を持つユーザーに**create**パーミッションが付与されているため、新しいCompanyエンティティを作成できます。

**リクエスト**

**メソッド：** POST

**URL：** http://127.0.0.1:80/rest/Company/?$method=update

**ボディ：**

```json
{
    "companyName": "4D",
    "email": "hello@4D.ma",
    "city": "Rabat",
    "createdAt": "2025-08-15T14:15:00Z"
  }
```

![](fig-15)

**処理の流れ：**

1. サーバーが、セッションに"AccessTOCOMPANY"権限があることを検証します
2. Companyデータクラスに対する**create**パーミッションが付与されます
3. 渡されたデータで新しいエンティティが作成されます
4. サーバーは、生成された__KEYと__STAMPを含むエンティティ全体を返します

### 既存のCompanyレコードの更新

**重要な注意点**：現在のroles.json設定では、Companyデータクラスに対する**update**パーミッションは**明示的に付与されていません**。そのため、"AccessTOCOMPANY"権限を持つ認証済みユーザーであっても、更新操作は**拒否**されます。roles.jsonファイルでは、Companyデータクラスは次のように設定されています：

```json
{
            "applyTo": "Company",
            "type": "dataclass",
            "read": [
                 "AccessTOCOMPANY"
            ],
            "create": [
                 "AccessTOCOMPANY"
            ],
            "drop": [
                 "AccessTOCOMPANY"
            ]
       },
```

**Postmanでのリクエスト**

**メソッド：** POST

**URL：** http://127.0.0.1:80/rest/Company/?$method=update

**ボディ：**

```json
{
    "ID": 3,
    "companyName": "Innovatechoo",
    "email": "hello@innovatech.ma",
    "city": "Marrakech",
    "createdAt": "2025-08-15T14:15:00Z"
  }
```

![](fig-16)

### Companyレコードの削除

"AccessTOCOMPANY"権限を持つユーザーには**drop**パーミッションが付与されているため、Companyエンティティを削除できます。

**リクエスト**

**メソッド：** POST

**URL：** http://localhost/rest/Company(2)?$method=delete

![](fig-17)

削除は成功し、エンティティはテーブルに存在しなくなりました。

![](fig-18)

## まとめ

4Dの強制ログインモードは、REST APIへのアクセスに、モダンでセキュア・バイ・デフォルトな基盤をもたらします。認証とライセンスの使用を切り離し、明示的な権限管理を徹底し、ロールに基づく柔軟なパーミッションシステムを提供します。強制ログインを採用することで、開発者は4Dアプリケーションを安全かつスケーラブルにし、モダンなWeb開発のベストプラクティスに沿ったものにできます。
