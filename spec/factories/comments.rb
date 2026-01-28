FactoryBot.define do
  factory :comment do
    association :article
    sequence(:author_name) { |n| "コメント投稿者#{n}" }
    body { 'テストコメント本文' }
  end
end
