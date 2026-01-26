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
        expect(article.errors[:title]).to include('を入力してください')
      end

      it 'titleがnilの場合、無効である' do
        article = build(:article, title: nil)
        expect(article).not_to be_valid
        expect(article.errors[:title]).to include('を入力してください')
      end

      it 'bodyが空の場合、無効である' do
        article = build(:article, body: '')
        expect(article).not_to be_valid
        expect(article.errors[:body]).to include('を入力してください')
      end

      it 'bodyがnilの場合、無効である' do
        article = build(:article, body: nil)
        expect(article).not_to be_valid
        expect(article.errors[:body]).to include('を入力してください')
      end

      it 'statusがpublishedでpublished_atがない場合、無効である' do
        article = build(:article, status: :published, published_at: nil)
        expect(article).not_to be_valid
        expect(article.errors[:published_at]).to include('を入力してください')
      end
    end

    # 境界値
    context '境界値' do
      it 'titleが255文字の場合、有効である' do
        article = build(:article, title: 'a' * 255)
        expect(article).to be_valid
      end

      it 'titleが256文字の場合、無効である' do
        article = build(:article, title: 'a' * 256)
        expect(article).not_to be_valid
        expect(article.errors[:title]).to include('は255文字以内で入力してください')
      end
    end
  end

  describe 'enum' do
    it 'statusにdraft, published, archivedが定義されていること' do
      expect(Article.statuses).to eq({ 'draft' => 0, 'published' => 1, 'archived' => 2 })
    end
  end
end
