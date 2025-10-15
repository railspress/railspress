# Storage Providers Seeds
puts "Creating storage providers..."

# Get the default tenant
default_tenant = Tenant.first

# Local storage provider (default)
StorageProvider.create!(
  name: "Local Storage",
  provider_type: "local",
  config: {
    local_path: Rails.root.join('storage').to_s
  },
  active: true,
  position: 1,
  tenant: default_tenant
)

# S3 compatible storage provider (inactive by default)
StorageProvider.create!(
  name: "S3 Compatible",
  provider_type: "s3",
  config: {
    access_key_id: "",
    secret_access_key: "",
    region: "us-east-1",
    bucket: "",
    endpoint: "" # Optional for custom S3-compatible services
  },
  active: false,
  position: 2,
  tenant: default_tenant
)

# Google Cloud Storage provider (inactive by default)
StorageProvider.create!(
  name: "Google Cloud Storage",
  provider_type: "gcs",
  config: {
    project: "",
    bucket: "",
    credentials: "" # JSON credentials
  },
  active: false,
  position: 3,
  tenant: default_tenant
)

# Azure Blob Storage provider (inactive by default)
StorageProvider.create!(
  name: "Azure Blob Storage",
  provider_type: "azure",
  config: {
    storage_account_name: "",
    storage_access_key: "",
    container: ""
  },
  active: false,
  position: 4,
  tenant: default_tenant
)

puts "Storage providers created successfully!"
