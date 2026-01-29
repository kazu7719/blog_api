require 'rails_helper'

RSpec.describe Comment, type: :model do
  describe 'バリデーション' do
    # 正常系
    context '有効なケース' do
      it '全ての属性が有効な場合、有効である' do
        comment = build(:comment)
        expect(comment).to be_valid
      end
    end

    # 異常系
    context '無効なケース' do
      it 'author_nameが空の場合、無効である' do
        comment = build(:comment, author_name: '')
        expect(comment).not_to be_valid
        expect(comment.errors[:author_name]).to include('投稿者名を入力してください')
      end

      it 'author_nameがnilの場合、無効である' do
        comment = build(:comment, author_name: nil)
        expect(comment).not_to be_valid
        expect(comment.errors[:author_name]).to include('投稿者名を入力してください')
      end

      it 'bodyが空の場合、無効である' do
        comment = build(:comment, body: '')
        expect(comment).not_to be_valid
        expect(comment.errors[:body]).to include('コメント本文を入力してください')
      end

      it 'bodyがnilの場合、無効である' do
        comment = build(:comment, body: nil)
        expect(comment).not_to be_valid
        expect(comment.errors[:body]).to include('コメント本文を入力してください')
      end

      it 'articleが関連付けられていない場合、無効である' do
        comment = build(:comment, article: nil)
        expect(comment).not_to be_valid
        expect(comment.errors[:article]).to be_present
      end
    end

    # 境界値
    context '境界値' do
      it 'author_nameが1文字の場合、有効である' do
        comment = build(:comment, author_name: 'a')
        expect(comment).to be_valid
      end

      it 'author_nameが50文字の場合、有効である' do
        comment = build(:comment, author_name: 'a' * 50)
        expect(comment).to be_valid
      end

      it 'author_nameが51文字の場合、無効である' do
        comment = build(:comment, author_name: 'a' * 51)
        expect(comment).not_to be_valid
        expect(comment.errors[:author_name]).to include('投稿者名は50文字以内で入力してください')
      end
    end
  end

  describe 'アソシエーション' do
    it 'articleに属する' do
      association = described_class.reflect_on_association(:article)
      expect(association.macro).to eq :belongs_to
    end

    it '親のarticleが削除されるとcommentも削除される' do
      article = create(:article)
      comment = create(:comment, article: article)
      expect { article.destroy }.to change { Comment.count }.by(-1)
    end

    it 'articleとの関連が正しく設定される' do
      article = create(:article)
      comment = create(:comment, article: article)
      expect(comment.article).to eq article
      expect(article.comments).to include(comment)
    end
  end
end
