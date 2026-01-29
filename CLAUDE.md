# Blog API

## プロジェクト概要
個人ブログサイトのバックエンドAPI

### モデル構成
- **Article（記事）**
  - 属性: title, body, status, published_at
  - enum: status (draft: 0, published: 1, archived: 2)
  - 関連: has_many :comments (dependent: :destroy)

- **Comment（コメント）**
  - 属性: author_name, body, article_id
  - 関連: belongs_to :article

### コントローラー構成
- **ArticlesController**
  - index: 公開済み記事の一覧（作成日時降順）
  - show: 記事の詳細
  - create: 記事の作成
  - update: 記事の更新
  - destroy: 記事の削除

- **CommentsController**
  - index: 特定記事のコメント一覧（作成日時降順）
  - create: コメントの作成
  - destroy: コメントの削除

### ルーティング構成
現在のエンドポイント:
- `/articles` - 記事リソース
- `/articles/:article_id/comments` - コメントリソース（articlesにネスト）

注: 現在はAPIバージョニングなしで実装。テストファイルは将来の`/api/v1`対応を見越して`spec/requests/api/v1/`配下に配置。

## 技術スタック
- Ruby on Rails 7.x (API mode)
- SQLite3（Railsのデフォルト）
- RSpec（テストフレームワーク）
- FactoryBot（テストデータ作成）

## 開発ルール

### 一般
- テストは必ず書く（RSpec）
- コミットは日本語で記述
- CRUD操作はRESTfulな設計に従う

### バリデーション
- エラーメッセージは日本語で記述
- 例: `presence: { message: 'を入力してください' }`
- エラーレスポンスは`{ errors: [...] }`形式で返す

### enum
- integer型で定義し、値は明示的に指定
- **必ず `_prefix: true` オプションを使用する**（メソッド名の衝突を防ぐため）
- 例: `enum status: { draft: 0, published: 1, archived: 2 }, _prefix: true`
- 使用例: `article.status_draft?`, `article.status_published?`

### カスタムバリデーション
- メソッド名: validate_カラム名_チェック内容
- 例: `validate_published_at_presence`

### API設計
- レスポンスステータスコード
  - 成功: 200 OK（取得・更新）, 201 Created（作成）, 204 No Content（削除）
  - エラー: 404 Not Found（リソース未存在）, 422 Unprocessable Entity（バリデーションエラー）
- ネストリソースの場合、親リソースIDは必須
  - 例: `/articles/:article_id/comments`
  - 親リソースが存在しない場合は404を返す

## テスト規約

### テストの構成順序
1. 正常系（有効なケース）
2. 異常系（無効なケース）
3. 境界値（制限値付近のケース）

### テストの実行
```bash
# 全てのテストを実行
bundle exec rspec

# 特定のファイルを実行
bundle exec rspec spec/models/article_spec.rb
bundle exec rspec spec/requests/api/v1/articles_spec.rb

# 特定の行番号のテストを実行
bundle exec rspec spec/models/article_spec.rb:10
```

### ファクトリ（FactoryBot）
- デフォルトは最小限の有効な状態
- バリエーションはtraitで定義

#### 基本的な使い方
```ruby
# ファクトリの定義例
FactoryBot.define do
  factory :article do
    sequence(:title) { |n| "テスト記事#{n}" }
    body { 'テスト本文' }
    status { :draft }

    trait :published do
      status { :published }
      published_at { Time.current }
    end
  end
end

# テストでの使用例
article = build(:article)                  # インスタンスのみ作成（DBに保存しない）
article = create(:article)                 # インスタンスを作成しDBに保存
article = create(:article, :published)     # traitを使用
articles = create_list(:article, 3)        # 複数作成
```

### テストのカバレッジ
#### モデルテスト
- バリデーションテスト（正常系、異常系、境界値）
- enumテスト（定義、デフォルト値、ステータス変更）
- アソシエーションテスト

#### リクエストスペック
- 各エンドポイントの正常系・異常系
- ステータスコードの検証
- JSONレスポンスの構造検証
- エラーメッセージの検証
- ネストリソースの関連性検証

## 開発時の注意点

### ArticlesController
- `index`アクションは公開済み（published）の記事のみを返す
- `Article.status_published`スコープを使用

### CommentsController
- 必ず親のArticleが存在することを確認（`set_article`）
- コメントは親のArticleに紐づいてのみ削除可能

### テストデータ
- Articleの一覧取得テストでは`:published` traitを使用すること
- Comment作成時は`author_name`と`body`が必須
- ネストリソースのテストでは親リソースの存在も確認すること
