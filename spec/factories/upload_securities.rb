FactoryBot.define do
  factory :upload_security do
    tenant
    max_file_size { 10.megabytes }
    allowed_extensions { ['jpg', 'jpeg', 'png', 'gif', 'webp', 'pdf', 'doc', 'docx', 'txt', 'csv', 'xlsx', 'ppt', 'pptx', 'zip'] }
    blocked_extensions { ['exe', 'bat', 'cmd', 'sh', 'php', 'js', 'html', 'htm', 'asp', 'aspx', 'jsp'] }
    allowed_mime_types { [
      'image/jpeg', 'image/png', 'image/gif', 'image/webp',
      'application/pdf',
      'text/plain', 'text/csv',
      'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'application/vnd.ms-excel', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'application/vnd.ms-powerpoint', 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'application/zip'
    ] }
    blocked_mime_types { [
      'application/x-executable', 'application/x-msdownload',
      'application/x-sh', 'application/x-bat',
      'text/html', 'text/javascript',
      'application/x-php', 'application/x-asp'
    ] }
    scan_for_viruses { false }
    quarantine_suspicious { true }
    auto_approve_trusted { false }

    trait :with_virus_scanning do
      scan_for_viruses { true }
    end

    trait :without_quarantine do
      quarantine_suspicious { false }
    end

    trait :auto_approve do
      auto_approve_trusted { true }
    end

    trait :restrictive do
      max_file_size { 1.megabyte }
      allowed_extensions { ['jpg', 'png'] }
      allowed_mime_types { ['image/jpeg', 'image/png'] }
    end

    trait :permissive do
      max_file_size { 100.megabytes }
      allowed_extensions { ['jpg', 'jpeg', 'png', 'gif', 'webp', 'pdf', 'doc', 'docx', 'txt', 'csv', 'xlsx', 'ppt', 'pptx', 'zip', 'mp4', 'mp3', 'wav'] }
      allowed_mime_types { [
        'image/jpeg', 'image/png', 'image/gif', 'image/webp',
        'application/pdf',
        'text/plain', 'text/csv',
        'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'application/vnd.ms-excel', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'application/vnd.ms-powerpoint', 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
        'application/zip',
        'video/mp4', 'audio/mpeg', 'audio/wav'
      ] }
    end
  end
end