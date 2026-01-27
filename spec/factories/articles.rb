FactoryBot.define do
  factory :article do
    sequence(:title) { |n| "テスト記事#{n}" }
    body { 'テスト本文' }
    status { :draft }

    trait :published do
      status { :published }
      published_at { Time.current }
    end

    trait :archived do
      status { :archived }
    end

    trait :with_long_title do
      title { 'a' * 100 }
    end
  end
end
