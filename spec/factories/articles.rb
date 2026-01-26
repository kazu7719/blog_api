FactoryBot.define do
  factory :article do
    title { 'テスト記事タイトル' }
    body { 'テスト記事本文' }
    status { :draft }

    trait :published do
      status { :published }
      published_at { Time.current }
    end

    trait :archived do
      status { :archived }
    end
  end
end
