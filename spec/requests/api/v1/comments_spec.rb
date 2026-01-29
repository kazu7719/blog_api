require 'rails_helper'

RSpec.describe 'Comments API', type: :request do
  let(:article) { create(:article, :published) }

  describe 'GET /articles/:article_id/comments' do
    # 正常系
    context 'コメントが存在する場合' do
      let!(:comments) { create_list(:comment, 3, article: article) }

      before { get "/articles/#{article.id}/comments" }

      it 'ステータスコード200を返す' do
        expect(response).to have_http_status(:ok)
      end

      it '記事に紐づくコメント一覧を返す' do
        json = JSON.parse(response.body)
        expect(json.length).to eq(3)
      end

      it 'コメントが作成日時の降順で返される' do
        json = JSON.parse(response.body)
        expect(json[0]['id']).to eq(comments.last.id)
        expect(json[2]['id']).to eq(comments.first.id)
      end

      it 'JSONレスポンスに必要な属性が含まれる' do
        json = JSON.parse(response.body)
        expect(json.first.keys).to include('id', 'author_name', 'body', 'article_id', 'created_at', 'updated_at')
      end
    end

    context 'コメントが存在しない場合' do
      before { get "/articles/#{article.id}/comments" }

      it 'ステータスコード200を返す' do
        expect(response).to have_http_status(:ok)
      end

      it '空の配列を返す' do
        json = JSON.parse(response.body)
        expect(json).to eq([])
      end
    end

    context '他の記事のコメントは含まれない' do
      let(:other_article) { create(:article, :published) }
      let!(:article_comments) { create_list(:comment, 2, article: article) }
      let!(:other_comments) { create_list(:comment, 3, article: other_article) }

      before { get "/articles/#{article.id}/comments" }

      it '指定した記事のコメントのみを返す' do
        json = JSON.parse(response.body)
        expect(json.length).to eq(2)
        json.each do |comment|
          expect(comment['article_id']).to eq(article.id)
        end
      end
    end

    # 異常系
    context '記事が存在しない場合' do
      before { get '/articles/99999/comments' }

      it 'ステータスコード404を返す' do
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST /articles/:article_id/comments' do
    # 正常系
    context '正しいパラメータの場合' do
      let(:valid_params) do
        {
          comment: {
            author_name: 'テスト太郎',
            body: 'これは素晴らしい記事ですね！'
          }
        }
      end

      it 'ステータスコード201を返す' do
        post "/articles/#{article.id}/comments", params: valid_params
        expect(response).to have_http_status(:created)
      end

      it 'コメントが作成される' do
        expect {
          post "/articles/#{article.id}/comments", params: valid_params
        }.to change(Comment, :count).by(1)
      end

      it '記事に紐づいたコメントが作成される' do
        post "/articles/#{article.id}/comments", params: valid_params
        expect(article.comments.count).to eq(1)
        expect(article.comments.last.author_name).to eq('テスト太郎')
      end

      it '作成されたコメントのJSONを返す' do
        post "/articles/#{article.id}/comments", params: valid_params
        json = JSON.parse(response.body)
        expect(json['author_name']).to eq('テスト太郎')
        expect(json['body']).to eq('これは素晴らしい記事ですね！')
        expect(json['article_id']).to eq(article.id)
      end

      it 'JSONレスポンスに必要な属性が含まれる' do
        post "/articles/#{article.id}/comments", params: valid_params
        json = JSON.parse(response.body)
        expect(json.keys).to include('id', 'author_name', 'body', 'article_id', 'created_at', 'updated_at')
      end
    end

    # 異常系
    context 'author_nameが空の場合' do
      let(:invalid_params) do
        {
          comment: {
            author_name: '',
            body: 'コメント本文'
          }
        }
      end

      it 'ステータスコード422を返す' do
        post "/articles/#{article.id}/comments", params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'コメントが作成されない' do
        expect {
          post "/articles/#{article.id}/comments", params: invalid_params
        }.not_to change(Comment, :count)
      end

      it 'エラーメッセージを返す' do
        post "/articles/#{article.id}/comments", params: invalid_params
        json = JSON.parse(response.body)
        expect(json['errors']).to be_present
        expect(json['errors']).to include('Author name 投稿者名を入力してください')
      end
    end

    context 'bodyが空の場合' do
      let(:invalid_params) do
        {
          comment: {
            author_name: 'テスト太郎',
            body: ''
          }
        }
      end

      it 'ステータスコード422を返す' do
        post "/articles/#{article.id}/comments", params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'コメントが作成されない' do
        expect {
          post "/articles/#{article.id}/comments", params: invalid_params
        }.not_to change(Comment, :count)
      end

      it 'エラーメッセージを返す' do
        post "/articles/#{article.id}/comments", params: invalid_params
        json = JSON.parse(response.body)
        expect(json['errors']).to be_present
        expect(json['errors']).to include('Body コメント本文を入力してください')
      end
    end

    context 'author_nameとbodyが両方空の場合' do
      let(:invalid_params) do
        {
          comment: {
            author_name: '',
            body: ''
          }
        }
      end

      it 'ステータスコード422を返す' do
        post "/articles/#{article.id}/comments", params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'コメントが作成されない' do
        expect {
          post "/articles/#{article.id}/comments", params: invalid_params
        }.not_to change(Comment, :count)
      end

      it '複数のエラーメッセージを返す' do
        post "/articles/#{article.id}/comments", params: invalid_params
        json = JSON.parse(response.body)
        expect(json['errors']).to be_present
        expect(json['errors'].length).to be >= 2
      end
    end

    context '記事が存在しない場合' do
      let(:valid_params) do
        {
          comment: {
            author_name: 'テスト太郎',
            body: 'コメント本文'
          }
        }
      end

      it 'ステータスコード404を返す' do
        post '/articles/99999/comments', params: valid_params
        expect(response).to have_http_status(:not_found)
      end

      it 'コメントが作成されない' do
        expect {
          post '/articles/99999/comments', params: valid_params
        }.not_to change(Comment, :count)
      end
    end

    context 'author_nameが51文字の場合' do
      let(:invalid_params) do
        {
          comment: {
            author_name: 'a' * 51,
            body: 'コメント本文'
          }
        }
      end

      it 'ステータスコード422を返す' do
        post "/articles/#{article.id}/comments", params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'エラーメッセージを返す' do
        post "/articles/#{article.id}/comments", params: invalid_params
        json = JSON.parse(response.body)
        expect(json['errors']).to be_present
        expect(json['errors']).to include('Author name 投稿者名は50文字以内で入力してください')
      end
    end
  end

  describe 'DELETE /articles/:article_id/comments/:id' do
    # 正常系
    context 'コメントが存在する場合' do
      let!(:comment) { create(:comment, article: article) }

      it 'ステータスコード204を返す' do
        delete "/articles/#{article.id}/comments/#{comment.id}"
        expect(response).to have_http_status(:no_content)
      end

      it 'コメントが削除される' do
        expect {
          delete "/articles/#{article.id}/comments/#{comment.id}"
        }.to change(Comment, :count).by(-1)
      end

      it 'レスポンスボディが空である' do
        delete "/articles/#{article.id}/comments/#{comment.id}"
        expect(response.body).to be_empty
      end

      it '記事に紐づくコメント数が減少する' do
        expect {
          delete "/articles/#{article.id}/comments/#{comment.id}"
        }.to change { article.comments.count }.by(-1)
      end
    end

    # 異常系
    context 'コメントが存在しない場合' do
      it 'ステータスコード404を返す' do
        delete "/articles/#{article.id}/comments/99999"
        expect(response).to have_http_status(:not_found)
      end
    end

    context '記事が存在しない場合' do
      it 'ステータスコード404を返す' do
        delete '/articles/99999/comments/1'
        expect(response).to have_http_status(:not_found)
      end
    end

    context '他の記事のコメントを削除しようとした場合' do
      let(:other_article) { create(:article, :published) }
      let!(:other_comment) { create(:comment, article: other_article) }

      it 'ステータスコード404を返す' do
        delete "/articles/#{article.id}/comments/#{other_comment.id}"
        expect(response).to have_http_status(:not_found)
      end

      it 'コメントが削除されない' do
        expect {
          delete "/articles/#{article.id}/comments/#{other_comment.id}"
        }.not_to change(Comment, :count)
      end
    end
  end
end
