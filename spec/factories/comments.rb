FactoryBot.define do
  factory :comment do
    content { "This is a test comment" }
    author_name { "Test Author" }
    author_email { "test@example.com" }
    author_url { "https://example.com" }
    author_ip { "127.0.0.1" }
    author_agent { "Test Browser" }
    comment_type { "comment" }
    comment_approved { "0" }
    status { "pending" }
    association :user
    association :commentable, factory: :post
    association :tenant
  end

  trait :approved do
    comment_approved { "1" }
    status { "approved" }
  end

  trait :pending do
    comment_approved { "0" }
    status { "pending" }
  end

  trait :spam do
    comment_approved { "0" }
    status { "spam" }
  end

  trait :trash do
    comment_approved { "0" }
    status { "trash" }
  end

  trait :reply do
    association :parent, factory: :comment
  end
end