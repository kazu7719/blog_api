require 'rails_helper'

RSpec.describe 'Articles API', type: :request do
  describe 'GET /articles' do
    # 正常系
    context '記事が存在する場合' do
      let!(:published_articles) { create_list(:article, 3, :published) }
      let!(:draft_articles) { create_list(:article, 2) }

      before { get '/articles' }

      it 'ステータスコード200を返す' do
        expect(response).to have_http_status(:ok)
      end

      it '公開済みの記事のみを返す' do
        json = JSON.parse(response.body)
        expect(json.length).to eq(3)
      end

      it '記事が作成日時の降順で返される' do
        json = JSON.parse(response.body)
        expect(json[0]['id']).to eq(published_articles.last.id)
        expect(json[2]['id']).to eq(published_articles.first.id)
      end

      it 'JSONレスポンスに必要な属性が含まれる' do
        json = JSON.parse(response.body)
        expect(json.first.keys).to include('id', 'title', 'body', 'status', 'published_at', 'created_at', 'updated_at')
      end
    end

    context '記事が存在しない場合' do
      before { get '/articles' }

      it 'ステータスコード200を返す' do
        expect(response).to have_http_status(:ok)
      end

      it '空の配列を返す' do
        json = JSON.parse(response.body)
        expect(json).to eq([])
      end
    end
  end

  describe 'GET /articles/:id' do
    # 正常系
    context '記事が存在する場合' do
      let(:article) { create(:article, :published) }

      before { get "/articles/#{article.id}" }

      it 'ステータスコード200を返す' do
        expect(response).to have_http_status(:ok)
      end

      it '記事の詳細を返す' do
        json = JSON.parse(response.body)
        expect(json['id']).to eq(article.id)
        expect(json['title']).to eq(article.title)
        expect(json['body']).to eq(article.body)
        expect(json['status']).to eq('published')
      end

      it 'JSONレスポンスに必要な属性が含まれる' do
        json = JSON.parse(response.body)
        expect(json.keys).to include('id', 'title', 'body', 'status', 'published_at', 'created_at', 'updated_at')
      end
    end

    # 異常系
    context '記事が存在しない場合' do
      before { get '/articles/99999' }

      it 'ステータスコード404を返す' do
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST /articles' do
    # 正常系
    context '正しいパラメータの場合' do
      let(:valid_params) do
        {
          article: {
            title: '新しい記事',
            body: '記事の本文',
            status: 'draft'
          }
        }
      end

      it 'ステータスコード201を返す' do
        post '/articles', params: valid_params
        expect(response).to have_http_status(:created)
      end

      it '記事が作成される' do
        expect {
          post '/articles', params: valid_params
        }.to change(Article, :count).by(1)
      end

      it '作成された記事のJSONを返す' do
        post '/articles', params: valid_params
        json = JSON.parse(response.body)
        expect(json['title']).to eq('新しい記事')
        expect(json['body']).to eq('記事の本文')
        expect(json['status']).to eq('draft')
      end

      it 'JSONレスポンスに必要な属性が含まれる' do
        post '/articles', params: valid_params
        json = JSON.parse(response.body)
        expect(json.keys).to include('id', 'title', 'body', 'status', 'created_at', 'updated_at')
      end
    end

    context 'published statusで公開日時を指定した場合' do
      let(:published_params) do
        {
          article: {
            title: '公開記事',
            body: '公開記事の本文',
            status: 'published',
            published_at: Time.current
          }
        }
      end

      it '記事が作成される' do
        expect {
          post '/articles', params: published_params
        }.to change(Article, :count).by(1)
      end

      it 'ステータスコード201を返す' do
        post '/articles', params: published_params
        expect(response).to have_http_status(:created)
      end
    end

    # 異常系
    context 'titleが空の場合' do
      let(:invalid_params) do
        {
          article: {
            title: '',
            body: '記事の本文'
          }
        }
      end

      it 'ステータスコード422を返す' do
        post '/articles', params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it '記事が作成されない' do
        expect {
          post '/articles', params: invalid_params
        }.not_to change(Article, :count)
      end

      it 'エラーメッセージを返す' do
        post '/articles', params: invalid_params
        json = JSON.parse(response.body)
        expect(json['errors']).to be_present
        expect(json['errors']).to include('Title タイトルを入力してください')
      end
    end

    context 'bodyが空の場合' do
      let(:invalid_params) do
        {
          article: {
            title: '記事タイトル',
            body: ''
          }
        }
      end

      it 'ステータスコード422を返す' do
        post '/articles', params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it '記事が作成されない' do
        expect {
          post '/articles', params: invalid_params
        }.not_to change(Article, :count)
      end

      it 'エラーメッセージを返す' do
        post '/articles', params: invalid_params
        json = JSON.parse(response.body)
        expect(json['errors']).to be_present
        expect(json['errors']).to include('Body 本文を入力してください')
      end
    end

    context 'published statusでpublished_atがない場合' do
      let(:invalid_params) do
        {
          article: {
            title: '記事タイトル',
            body: '記事の本文',
            status: 'published'
          }
        }
      end

      it 'ステータスコード422を返す' do
        post '/articles', params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it '記事が作成されない' do
        expect {
          post '/articles', params: invalid_params
        }.not_to change(Article, :count)
      end

      it 'エラーメッセージを返す' do
        post '/articles', params: invalid_params
        json = JSON.parse(response.body)
        expect(json['errors']).to be_present
        expect(json['errors']).to include('Published at を入力してください')
      end
    end
  end

  describe 'PATCH /articles/:id' do
    let(:article) { create(:article) }

    # 正常系
    context '正しいパラメータの場合' do
      let(:valid_params) do
        {
          article: {
            title: '更新されたタイトル',
            body: '更新された本文'
          }
        }
      end

      before { patch "/articles/#{article.id}", params: valid_params }

      it 'ステータスコード200を返す' do
        expect(response).to have_http_status(:ok)
      end

      it '記事が更新される' do
        article.reload
        expect(article.title).to eq('更新されたタイトル')
        expect(article.body).to eq('更新された本文')
      end

      it '更新された記事のJSONを返す' do
        json = JSON.parse(response.body)
        expect(json['title']).to eq('更新されたタイトル')
        expect(json['body']).to eq('更新された本文')
      end
    end

    context 'statusをpublishedに変更する場合' do
      let(:update_params) do
        {
          article: {
            status: 'published',
            published_at: Time.current
          }
        }
      end

      it '記事が更新される' do
        patch "/articles/#{article.id}", params: update_params
        article.reload
        expect(article.status).to eq('published')
        expect(article.published_at).to be_present
      end

      it 'ステータスコード200を返す' do
        patch "/articles/#{article.id}", params: update_params
        expect(response).to have_http_status(:ok)
      end
    end

    # 異常系
    context '記事が存在しない場合' do
      let(:valid_params) do
        {
          article: {
            title: '更新されたタイトル'
          }
        }
      end

      before { patch '/articles/99999', params: valid_params }

      it 'ステータスコード404を返す' do
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'titleを空にする場合' do
      let(:invalid_params) do
        {
          article: {
            title: ''
          }
        }
      end

      before { patch "/articles/#{article.id}", params: invalid_params }

      it 'ステータスコード422を返す' do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it '記事が更新されない' do
        article.reload
        expect(article.title).not_to eq('')
      end

      it 'エラーメッセージを返す' do
        json = JSON.parse(response.body)
        expect(json['errors']).to be_present
        expect(json['errors']).to include('Title タイトルを入力してください')
      end
    end

    context 'bodyを空にする場合' do
      let(:invalid_params) do
        {
          article: {
            body: ''
          }
        }
      end

      before { patch "/articles/#{article.id}", params: invalid_params }

      it 'ステータスコード422を返す' do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it '記事が更新されない' do
        article.reload
        expect(article.body).not_to eq('')
      end

      it 'エラーメッセージを返す' do
        json = JSON.parse(response.body)
        expect(json['errors']).to be_present
        expect(json['errors']).to include('Body 本文を入力してください')
      end
    end
  end

  describe 'DELETE /articles/:id' do
    # 正常系
    context '記事が存在する場合' do
      let!(:article) { create(:article) }

      it 'ステータスコード204を返す' do
        delete "/articles/#{article.id}"
        expect(response).to have_http_status(:no_content)
      end

      it '記事が削除される' do
        expect {
          delete "/articles/#{article.id}"
        }.to change(Article, :count).by(-1)
      end

      it 'レスポンスボディが空である' do
        delete "/articles/#{article.id}"
        expect(response.body).to be_empty
      end
    end

    context '記事にコメントが紐づいている場合' do
      let!(:article) { create(:article) }
      let!(:comment) { create(:comment, article: article) }

      it '記事とコメントが両方削除される' do
        expect {
          delete "/articles/#{article.id}"
        }.to change(Article, :count).by(-1)
         .and change(Comment, :count).by(-1)
      end

      it 'ステータスコード204を返す' do
        delete "/articles/#{article.id}"
        expect(response).to have_http_status(:no_content)
      end
    end

    # 異常系
    context '記事が存在しない場合' do
      before { delete '/articles/99999' }

      it 'ステータスコード404を返す' do
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
