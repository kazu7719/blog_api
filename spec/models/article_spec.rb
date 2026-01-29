require 'rails_helper'

RSpec.describe Article, type: :model do
  describe 'バリデーション' do
    # 正常系
    context '有効なケース' do
      it '全ての属性が有効な場合、有効である' do
        article = build(:article)
        expect(article).to be_valid
      end

      it 'statusがpublishedでpublished_atがある場合、有効である' do
        article = build(:article, :published)
        expect(article).to be_valid
      end

      it 'statusがarchivedの場合、published_atがなくても有効である' do
        article = build(:article, :archived)
        expect(article).to be_valid
      end
    end

    # 異常系
    context '無効なケース' do
      it 'titleが空の場合、無効である' do
        article = build(:article, title: '')
        expect(article).not_to be_valid
        expect(article.errors[:title]).to include('タイトルを入力してください')
      end

      it 'titleがnilの場合、無効である' do
        article = build(:article, title: nil)
        expect(article).not_to be_valid
        expect(article.errors[:title]).to include('タイトルを入力してください')
      end

      it 'bodyが空の場合、無効である' do
        article = build(:article, body: '')
        expect(article).not_to be_valid
        expect(article.errors[:body]).to include('本文を入力してください')
      end

      it 'bodyがnilの場合、無効である' do
        article = build(:article, body: nil)
        expect(article).not_to be_valid
        expect(article.errors[:body]).to include('本文を入力してください')
      end

      it 'statusがpublishedでpublished_atがない場合、無効である' do
        article = build(:article, status: :published, published_at: nil)
        expect(article).not_to be_valid
        expect(article.errors[:published_at]).to include('を入力してください')
      end
    end

    # 境界値
    context '境界値' do
      it 'titleが100文字の場合、有効である' do
        article = build(:article, title: 'a' * 100)
        expect(article).to be_valid
      end

      it 'titleが101文字の場合、無効である' do
        article = build(:article, title: 'a' * 101)
        expect(article).not_to be_valid
        expect(article.errors[:title]).to include('タイトルは100文字以内で入力してください')
      end
    end
  end

  describe 'enum' do
    it 'statusにdraft, published, archivedが定義されていること' do
      expect(Article.statuses).to eq({ 'draft' => 0, 'published' => 1, 'archived' => 2 })
    end

    it 'デフォルトのstatusはdraftである' do
      article = Article.new
      expect(article.status).to eq('draft')
    end

    it 'statusをpublishedに変更できる' do
      article = create(:article)
      article.update(status: :published, published_at: Time.current)
      expect(article.status_published?).to be true
    end

    it 'statusをarchivedに変更できる' do
      article = create(:article)
      article.update(status: :archived)
      expect(article.status_archived?).to be true
    end

    it 'status_draft?メソッドが正しく動作する' do
      article = build(:article)
      expect(article.status_draft?).to be true
    end

    it 'status_published?メソッドが正しく動作する' do
      article = build(:article, :published)
      expect(article.status_published?).to be true
    end

    it 'status_archived?メソッドが正しく動作する' do
      article = build(:article, :archived)
      expect(article.status_archived?).to be true
    end
  end

  describe 'アソシエーション' do
    it 'commentsを持つ' do
      association = described_class.reflect_on_association(:comments)
      expect(association.macro).to eq :has_many
    end

    it '記事を削除すると関連するコメントも削除される' do
      article = create(:article)
      create(:comment, article: article)
      expect { article.destroy }.to change { Comment.count }.by(-1)
    end
  end
end
