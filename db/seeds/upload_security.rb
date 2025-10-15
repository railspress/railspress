# Upload Security Seeds
puts "Creating upload security settings..."

# Get the default tenant
default_tenant = Tenant.first

# Create default upload security settings
UploadSecurity.create!(
  max_file_size: 10.megabytes,
  allowed_extensions: %w[jpg jpeg png gif webp pdf doc docx txt csv xlsx ppt pptx zip],
  blocked_extensions: %w[exe bat cmd sh php js html htm asp aspx jsp],
  allowed_mime_types: %w[
    image/jpeg image/png image/gif image/webp
    application/pdf
    text/plain text/csv
    application/msword application/vnd.openxmlformats-officedocument.wordprocessingml.document
    application/vnd.ms-excel application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
    application/vnd.ms-powerpoint application/vnd.openxmlformats-officedocument.presentationml.presentation
    application/zip
  ],
  blocked_mime_types: %w[
    application/x-executable application/x-msdownload
    application/x-sh application/x-bat
    text/html text/javascript
    application/x-php application/x-asp
  ],
  scan_for_viruses: false,
  quarantine_suspicious: true,
  auto_approve_trusted: false,
  tenant: default_tenant
)

puts "Upload security settings created successfully!"

