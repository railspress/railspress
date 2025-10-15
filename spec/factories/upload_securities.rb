FactoryBot.define do
  factory :upload_security do
    max_file_size { 1 }
    allowed_extensions { "MyText" }
    blocked_extensions { "MyText" }
    allowed_mime_types { "MyText" }
    blocked_mime_types { "MyText" }
    scan_for_viruses { false }
    quarantine_suspicious { false }
    auto_approve_trusted { false }
    tenant { nil }
  end
end
