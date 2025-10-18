FactoryBot.define do
  factory :upload do
    tenant
    user
    title { Faker::Lorem.word }
    description { Faker::Lorem.sentence }
    alt_text { Faker::Lorem.sentence }
    quarantined { false }
    quarantine_reason { nil }

    # Create a simple text file for basic uploads
    after(:build) do |upload|
      upload.file.attach(
        io: StringIO.new("test file content"),
        filename: "#{Faker::File.file_name}.txt",
        content_type: 'text/plain'
      )
    end

    trait :with_image do
      after(:build) do |upload|
        # Create a simple image file (1x1 pixel PNG)
        image_data = Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==")
        upload.file.attach(
          io: StringIO.new(image_data),
          filename: "#{Faker::File.file_name}.jpg",
          content_type: 'image/jpeg'
        )
      end
    end

    trait :with_video do
      after(:build) do |upload|
        # Create a minimal video file (just a placeholder)
        video_data = "fake video content for testing"
        upload.file.attach(
          io: StringIO.new(video_data),
          filename: "#{Faker::File.file_name}.mp4",
          content_type: 'video/mp4'
        )
      end
    end

    trait :with_document do
      after(:build) do |upload|
        # Create a simple PDF-like file
        pdf_data = "%PDF-1.4\n1 0 obj\n<<\n/Type /Catalog\n/Pages 2 0 R\n>>\nendobj\n"
        upload.file.attach(
          io: StringIO.new(pdf_data),
          filename: "#{Faker::File.file_name}.pdf",
          content_type: 'application/pdf'
        )
      end
    end

    trait :quarantined do
      quarantined { true }
      quarantine_reason { 'Suspicious file pattern detected' }
    end

    trait :large_file do
      after(:build) do |upload|
        # Create a large file (simulate large file)
        large_data = "x" * (5 * 1024 * 1024) # 5MB
        upload.file.attach(
          io: StringIO.new(large_data),
          filename: "#{Faker::File.file_name}.txt",
          content_type: 'text/plain'
        )
      end
    end

    trait :with_storage_provider do
      association :storage_provider, factory: :storage_provider
    end

    trait :approved do
      quarantined { false }
      quarantine_reason { nil }
    end

    trait :rejected do
      quarantined { true }
      quarantine_reason { 'File type not allowed' }
    end
  end
end