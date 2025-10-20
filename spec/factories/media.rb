FactoryBot.define do
  factory :medium do
    title { "Test Media" }
    description { "Test media description" }
    file_url { "https://example.com/file.jpg" }
    thumbnail_url { "https://example.com/thumb.jpg" }
    file_size { 1024 }
    mime_type { "image/jpeg" }
    alt_text { "Test image" }
    association :user
    association :tenant
  end

  trait :image do
    title { "Test Image" }
    file_url { "https://example.com/image.jpg" }
    mime_type { "image/jpeg" }
  end

  trait :video do
    title { "Test Video" }
    file_url { "https://example.com/video.mp4" }
    mime_type { "video/mp4" }
  end

  trait :document do
    title { "Test Document" }
    file_url { "https://example.com/document.pdf" }
    mime_type { "application/pdf" }
  end

  trait :large_file do
    file_size { 10.megabytes }
  end
end
