class Comment < ApplicationRecord
  belongs_to :article

  validates :author_name, presence: { message: '投稿者名を入力してください' },
                          length: { minimum: 1, maximum: 50, message: '投稿者名は50文字以内で入力してください', allow_blank: true }
  validates :body, presence: { message: 'コメント本文を入力してください' }
end
