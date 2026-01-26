class Article < ApplicationRecord
  enum status: { draft: 0, published: 1, archived: 2 }

  validates :title, presence: { message: 'を入力してください' },
                    length: { maximum: 255, message: 'は255文字以内で入力してください' }
  validates :body, presence: { message: 'を入力してください' }
  validates :status, presence: { message: 'を入力してください' }

  validate :validate_published_at_presence

  private

  def validate_published_at_presence
    if published? && published_at.blank?
      errors.add(:published_at, 'を入力してください')
    end
  end
end
