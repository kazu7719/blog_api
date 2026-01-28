class Article < ApplicationRecord
  has_many :comments, dependent: :destroy

  enum status: { draft: 0, published: 1, archived: 2 }, _prefix: true

  validates :title, presence: { message: 'タイトルを入力してください' },
                    length: { maximum: 100, message: 'タイトルは100文字以内で入力してください', allow_blank: true }
  validates :body, presence: { message: '本文を入力してください' }
  validates :status, presence: { message: 'を入力してください' }

  validate :validate_published_at_presence

  private

  def validate_published_at_presence
    if status_published? && published_at.blank?
      errors.add(:published_at, 'を入力してください')
    end
  end
end
