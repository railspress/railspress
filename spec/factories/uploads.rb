FactoryBot.define do
  factory :upload do
    filename { "test_file.jpg" }
    content_type { "image/jpeg" }
    file_size { 1024 }
    file_url { "https://example.com/test_file.jpg" }
    file_type { "image" }
    status { "ready" }
    association :user
    association :tenant
  end

  trait :image_file do
    filename { "image.jpg" }
    content_type { "image/jpeg" }
    file_type { "image" }
  end

  trait :video_file do
    filename { "video.mp4" }
    content_type { "video/mp4" }
    file_type { "video" }
  end

  trait :document_file do
    filename { "document.pdf" }
    content_type { "application/pdf" }
    file_type { "document" }
  end

  trait :ready do
    status { "ready" }
  end

  trait :processing do
    status { "processing" }
  end

  trait :failed do
    status { "failed" }
  end
end