# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2025_10_23_031541) do
  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "admin_notifications", force: :cascade do |t|
    t.string "plugin"
    t.text "message"
    t.string "notification_type"
    t.json "metadata"
    t.boolean "read"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "ai_agents", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "agent_type"
    t.text "prompt"
    t.text "content"
    t.text "guidelines"
    t.text "rules"
    t.text "tasks"
    t.text "master_prompt"
    t.integer "ai_provider_id", null: false
    t.boolean "active"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "slug"
    t.index ["ai_provider_id"], name: "index_ai_agents_on_ai_provider_id"
    t.index ["slug"], name: "index_ai_agents_on_slug", unique: true
  end

  create_table "ai_providers", force: :cascade do |t|
    t.string "name"
    t.string "provider_type"
    t.string "api_key"
    t.string "api_url"
    t.string "model_identifier"
    t.integer "max_tokens"
    t.decimal "temperature"
    t.boolean "active"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "ai_usages", force: :cascade do |t|
    t.integer "ai_agent_id", null: false
    t.integer "user_id", null: false
    t.text "prompt"
    t.text "response"
    t.integer "tokens_used"
    t.decimal "cost"
    t.decimal "response_time"
    t.boolean "success"
    t.text "error_message"
    t.json "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ai_agent_id"], name: "index_ai_usages_on_ai_agent_id"
    t.index ["user_id"], name: "index_ai_usages_on_user_id"
  end

  create_table "analytics_audit_logs", force: :cascade do |t|
    t.integer "user_id"
    t.integer "admin_user_id"
    t.integer "tenant_id"
    t.string "data_type", null: false
    t.string "action", null: false
    t.datetime "timestamp", null: false
    t.string "ip_address"
    t.text "user_agent"
    t.text "details"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["action"], name: "index_analytics_audit_logs_on_action"
    t.index ["admin_user_id"], name: "index_analytics_audit_logs_on_admin_user_id"
    t.index ["data_type"], name: "index_analytics_audit_logs_on_data_type"
    t.index ["tenant_id"], name: "index_analytics_audit_logs_on_tenant_id"
    t.index ["timestamp"], name: "index_analytics_audit_logs_on_timestamp"
    t.index ["user_id"], name: "index_analytics_audit_logs_on_user_id"
  end

  create_table "analytics_consents", force: :cascade do |t|
    t.integer "user_id"
    t.integer "tenant_id"
    t.string "consent_type", null: false
    t.boolean "granted", null: false
    t.string "purpose"
    t.datetime "timestamp", null: false
    t.string "ip_address"
    t.text "user_agent"
    t.text "consent_details"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["consent_type"], name: "index_analytics_consents_on_consent_type"
    t.index ["granted"], name: "index_analytics_consents_on_granted"
    t.index ["tenant_id"], name: "index_analytics_consents_on_tenant_id"
    t.index ["timestamp"], name: "index_analytics_consents_on_timestamp"
    t.index ["user_id"], name: "index_analytics_consents_on_user_id"
  end

  create_table "analytics_data_deletions", force: :cascade do |t|
    t.integer "user_id"
    t.integer "admin_user_id"
    t.integer "tenant_id"
    t.text "data_types", null: false
    t.datetime "timestamp", null: false
    t.text "deletion_details"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_user_id"], name: "index_analytics_data_deletions_on_admin_user_id"
    t.index ["tenant_id"], name: "index_analytics_data_deletions_on_tenant_id"
    t.index ["timestamp"], name: "index_analytics_data_deletions_on_timestamp"
    t.index ["user_id"], name: "index_analytics_data_deletions_on_user_id"
  end

  create_table "analytics_events", force: :cascade do |t|
    t.string "event_name"
    t.text "properties"
    t.string "session_id"
    t.integer "user_id"
    t.string "path"
    t.integer "tenant_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id"], name: "index_analytics_events_on_tenant_id"
  end

  create_table "api_tokens", force: :cascade do |t|
    t.string "name", null: false
    t.string "token", null: false
    t.integer "user_id", null: false
    t.string "role", default: "public", null: false
    t.json "permissions", default: {}
    t.datetime "expires_at"
    t.datetime "last_used_at"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_api_tokens_on_active"
    t.index ["role"], name: "index_api_tokens_on_role"
    t.index ["token"], name: "index_api_tokens_on_token", unique: true
    t.index ["user_id", "name"], name: "index_api_tokens_on_user_id_and_name", unique: true
    t.index ["user_id"], name: "index_api_tokens_on_user_id"
  end

  create_table "archived_analytics_events", force: :cascade do |t|
    t.string "event_name", null: false
    t.json "properties"
    t.string "session_id"
    t.integer "user_id"
    t.integer "tenant_id", null: false
    t.datetime "created_at"
    t.datetime "archived_at"
    t.string "archive_batch_id"
    t.datetime "updated_at"
    t.index ["archive_batch_id"], name: "index_archived_analytics_events_on_archive_batch_id"
    t.index ["archived_at"], name: "index_archived_analytics_events_on_archived_at"
    t.index ["created_at"], name: "index_archived_analytics_events_on_created_at"
    t.index ["event_name"], name: "index_archived_analytics_events_on_event_name"
    t.index ["session_id"], name: "index_archived_analytics_events_on_session_id"
    t.index ["tenant_id"], name: "index_archived_analytics_events_on_tenant_id"
    t.index ["user_id"], name: "index_archived_analytics_events_on_user_id"
  end

  create_table "archived_pageviews", force: :cascade do |t|
    t.string "path"
    t.string "title"
    t.text "referrer"
    t.text "user_agent"
    t.string "browser"
    t.string "device"
    t.string "os"
    t.string "ip_hash"
    t.string "session_id"
    t.integer "user_id"
    t.integer "post_id"
    t.integer "page_id"
    t.boolean "unique_visitor", default: false
    t.boolean "returning_visitor", default: false
    t.boolean "bot", default: false
    t.boolean "consented", default: false
    t.datetime "visited_at"
    t.json "metadata"
    t.integer "tenant_id", null: false
    t.integer "reading_time"
    t.integer "scroll_depth"
    t.decimal "completion_rate", precision: 5, scale: 2
    t.integer "time_on_page"
    t.boolean "exit_intent", default: false
    t.string "country_code"
    t.string "country_name"
    t.string "city"
    t.string "region"
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.string "timezone"
    t.boolean "is_reader", default: false
    t.integer "engagement_score", default: 0
    t.datetime "archived_at"
    t.string "archive_batch_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["archive_batch_id"], name: "index_archived_pageviews_on_archive_batch_id"
    t.index ["archived_at"], name: "index_archived_pageviews_on_archived_at"
    t.index ["browser"], name: "index_archived_pageviews_on_browser"
    t.index ["country_code"], name: "index_archived_pageviews_on_country_code"
    t.index ["device"], name: "index_archived_pageviews_on_device"
    t.index ["is_reader"], name: "index_archived_pageviews_on_is_reader"
    t.index ["page_id"], name: "index_archived_pageviews_on_page_id"
    t.index ["post_id"], name: "index_archived_pageviews_on_post_id"
    t.index ["session_id"], name: "index_archived_pageviews_on_session_id"
    t.index ["tenant_id"], name: "index_archived_pageviews_on_tenant_id"
    t.index ["user_id"], name: "index_archived_pageviews_on_user_id"
    t.index ["visited_at"], name: "index_archived_pageviews_on_visited_at"
  end

  create_table "builder_file_settings", force: :cascade do |t|
    t.integer "builder_file_id", null: false
    t.integer "tenant_id", null: false
    t.json "meta", default: "{}", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["builder_file_id", "tenant_id"], name: "index_builder_file_settings_on_builder_file_id_and_tenant_id", unique: true
    t.index ["builder_file_id"], name: "index_builder_file_settings_on_builder_file_id"
    t.index ["tenant_id"], name: "index_builder_file_settings_on_tenant_id"
  end

  create_table "builder_page_sections", force: :cascade do |t|
    t.integer "builder_page_id", null: false
    t.integer "tenant_id", null: false
    t.string "section_id", null: false
    t.string "section_type", null: false
    t.text "settings", null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["builder_page_id", "position"], name: "index_builder_page_sections_on_builder_page_id_and_position"
    t.index ["builder_page_id", "section_id"], name: "index_builder_page_sections_on_builder_page_id_and_section_id", unique: true
    t.index ["builder_page_id"], name: "index_builder_page_sections_on_builder_page_id"
    t.index ["tenant_id"], name: "index_builder_page_sections_on_tenant_id"
  end

  create_table "builder_pages", force: :cascade do |t|
    t.integer "builder_theme_id", null: false
    t.integer "tenant_id", null: false
    t.string "template_name", null: false
    t.string "page_title", null: false
    t.text "settings"
    t.text "sections"
    t.integer "position", default: 0, null: false
    t.boolean "published", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["builder_theme_id", "position"], name: "index_builder_pages_on_builder_theme_id_and_position"
    t.index ["builder_theme_id", "published"], name: "index_builder_pages_on_builder_theme_id_and_published"
    t.index ["builder_theme_id", "template_name"], name: "index_builder_pages_on_builder_theme_id_and_template_name", unique: true
    t.index ["builder_theme_id"], name: "index_builder_pages_on_builder_theme_id"
    t.index ["tenant_id"], name: "index_builder_pages_on_tenant_id"
  end

  create_table "builder_theme_files", force: :cascade do |t|
    t.integer "builder_theme_id", null: false
    t.string "path", null: false
    t.text "content", null: false
    t.string "checksum", null: false
    t.integer "file_size"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tenant_id", null: false
    t.index ["builder_theme_id", "path"], name: "index_builder_theme_files_on_builder_theme_id_and_path", unique: true
    t.index ["builder_theme_id"], name: "index_builder_theme_files_on_builder_theme_id"
    t.index ["checksum"], name: "index_builder_theme_files_on_checksum"
    t.index ["tenant_id"], name: "index_builder_theme_files_on_tenant_id"
  end

  create_table "builder_theme_sections", force: :cascade do |t|
    t.integer "builder_theme_id", null: false
    t.integer "tenant_id", null: false
    t.string "section_id", null: false
    t.string "section_type", null: false
    t.text "settings", null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["builder_theme_id", "position"], name: "index_builder_theme_sections_on_builder_theme_id_and_position"
    t.index ["builder_theme_id", "section_id"], name: "idx_on_builder_theme_id_section_id_2761c3cdc8", unique: true
    t.index ["builder_theme_id"], name: "index_builder_theme_sections_on_builder_theme_id"
    t.index ["tenant_id"], name: "index_builder_theme_sections_on_tenant_id"
  end

  create_table "builder_theme_snapshots", force: :cascade do |t|
    t.string "theme_name", null: false
    t.integer "builder_theme_id", null: false
    t.text "settings_data", null: false
    t.text "sections_data", null: false
    t.string "checksum", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tenant_id", null: false
    t.index ["builder_theme_id"], name: "index_builder_theme_snapshots_on_builder_theme_id"
    t.index ["checksum"], name: "index_builder_theme_snapshots_on_checksum", unique: true
    t.index ["tenant_id"], name: "index_builder_theme_snapshots_on_tenant_id"
    t.index ["theme_name", "created_at"], name: "index_builder_theme_snapshots_on_theme_name_and_created_at"
    t.index ["user_id"], name: "index_builder_theme_snapshots_on_user_id"
  end

  create_table "builder_themes", force: :cascade do |t|
    t.string "theme_name", null: false
    t.string "label", null: false
    t.integer "parent_version_id"
    t.string "checksum", null: false
    t.boolean "published", default: false, null: false
    t.integer "user_id", null: false
    t.text "summary"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tenant_id", null: false
    t.index ["checksum"], name: "index_builder_themes_on_checksum", unique: true
    t.index ["parent_version_id"], name: "index_builder_themes_on_parent_version_id"
    t.index ["tenant_id"], name: "index_builder_themes_on_tenant_id"
    t.index ["theme_name", "published"], name: "index_builder_themes_on_theme_name_and_published"
    t.index ["user_id"], name: "index_builder_themes_on_user_id"
  end

  create_table "channel_overrides", force: :cascade do |t|
    t.integer "channel_id", null: false
    t.string "resource_type", null: false
    t.integer "resource_id"
    t.string "kind", null: false
    t.string "path", null: false
    t.json "data", default: {}
    t.boolean "enabled", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["channel_id", "resource_type", "resource_id"], name: "idx_on_channel_id_resource_type_resource_id_f941b041c6"
    t.index ["channel_id"], name: "index_channel_overrides_on_channel_id"
    t.index ["path"], name: "index_channel_overrides_on_path"
    t.index ["resource_type", "resource_id"], name: "index_channel_overrides_on_resource_type_and_resource_id"
  end

  create_table "channels", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.string "domain"
    t.string "locale", default: "en"
    t.json "metadata", default: {}
    t.json "settings", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "enabled", default: true, null: false
    t.index ["domain"], name: "index_channels_on_domain"
    t.index ["slug"], name: "index_channels_on_slug", unique: true
  end

  create_table "channels_media", id: false, force: :cascade do |t|
    t.integer "channel_id", null: false
    t.integer "medium_id", null: false
  end

  create_table "channels_pages", id: false, force: :cascade do |t|
    t.integer "channel_id", null: false
    t.integer "page_id", null: false
  end

  create_table "channels_posts", id: false, force: :cascade do |t|
    t.integer "channel_id", null: false
    t.integer "post_id", null: false
  end

  create_table "comments", force: :cascade do |t|
    t.text "content"
    t.string "author_name"
    t.string "author_email"
    t.string "author_url"
    t.integer "status"
    t.integer "user_id"
    t.string "commentable_type", null: false
    t.integer "commentable_id", null: false
    t.integer "parent_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tenant_id"
    t.datetime "deleted_at"
    t.integer "trashed_by_id"
    t.string "author_ip"
    t.string "comment_approved", limit: 20
    t.text "author_agent"
    t.string "comment_type"
    t.integer "comment_parent_id"
    t.index ["author_ip"], name: "index_comments_on_author_ip"
    t.index ["comment_approved"], name: "index_comments_on_comment_approved"
    t.index ["comment_parent_id"], name: "index_comments_on_comment_parent_id"
    t.index ["comment_type"], name: "index_comments_on_comment_type"
    t.index ["commentable_type", "commentable_id"], name: "index_comments_on_commentable"
    t.index ["deleted_at"], name: "index_comments_on_deleted_at"
    t.index ["parent_id"], name: "index_comments_on_parent_id"
    t.index ["tenant_id"], name: "index_comments_on_tenant_id"
    t.index ["trashed_by_id"], name: "index_comments_on_trashed_by_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "consent_configurations", force: :cascade do |t|
    t.string "name"
    t.string "banner_type"
    t.string "consent_mode"
    t.text "consent_categories"
    t.text "pixel_consent_mapping"
    t.text "banner_settings"
    t.text "geolocation_settings"
    t.boolean "active"
    t.integer "tenant_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["tenant_id"], name: "index_consent_configurations_on_tenant_id"
  end

  create_table "content_types", force: :cascade do |t|
    t.string "ident", null: false
    t.string "label", null: false
    t.string "singular", null: false
    t.string "plural", null: false
    t.text "description"
    t.string "icon"
    t.boolean "public", default: true
    t.boolean "hierarchical", default: false
    t.boolean "has_archive", default: true
    t.integer "menu_position"
    t.text "supports"
    t.text "capabilities"
    t.string "rest_base"
    t.boolean "active", default: true
    t.integer "tenant_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_content_types_on_active"
    t.index ["ident"], name: "index_content_types_on_ident", unique: true
    t.index ["tenant_id"], name: "index_content_types_on_tenant_id"
  end

  create_table "custom_field_values", force: :cascade do |t|
    t.integer "custom_field_id", null: false
    t.integer "post_id"
    t.integer "page_id"
    t.string "meta_key", null: false
    t.text "value"
    t.integer "tenant_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["custom_field_id"], name: "index_custom_field_values_on_custom_field_id"
    t.index ["meta_key"], name: "index_custom_field_values_on_meta_key"
    t.index ["page_id", "meta_key"], name: "index_custom_field_values_on_page_id_and_meta_key"
    t.index ["page_id"], name: "index_custom_field_values_on_page_id"
    t.index ["post_id", "meta_key"], name: "index_custom_field_values_on_post_id_and_meta_key"
    t.index ["post_id"], name: "index_custom_field_values_on_post_id"
    t.index ["tenant_id"], name: "index_custom_field_values_on_tenant_id"
  end

  create_table "custom_fields", force: :cascade do |t|
    t.integer "field_group_id", null: false
    t.string "name", null: false
    t.string "label", null: false
    t.string "field_type", null: false
    t.text "instructions"
    t.boolean "required", default: false
    t.text "default_value"
    t.text "choices"
    t.text "conditional_logic"
    t.integer "position", default: 0
    t.text "settings"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["field_group_id"], name: "index_custom_fields_on_field_group_id"
    t.index ["field_type"], name: "index_custom_fields_on_field_type"
    t.index ["name"], name: "index_custom_fields_on_name"
    t.index ["position"], name: "index_custom_fields_on_position"
  end

  create_table "custom_fonts", force: :cascade do |t|
    t.string "name", null: false
    t.string "family", null: false
    t.string "source", default: "google", null: false
    t.string "url"
    t.text "weights"
    t.text "styles"
    t.string "fallback", default: "sans-serif"
    t.boolean "active", default: true
    t.integer "tenant_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_custom_fonts_on_active"
    t.index ["family"], name: "index_custom_fonts_on_family"
    t.index ["name"], name: "index_custom_fonts_on_name"
    t.index ["source"], name: "index_custom_fonts_on_source"
    t.index ["tenant_id"], name: "index_custom_fonts_on_tenant_id"
  end

  create_table "email_logs", force: :cascade do |t|
    t.string "from_address"
    t.string "to_address"
    t.string "subject"
    t.text "body"
    t.string "status"
    t.string "provider"
    t.text "error_message"
    t.datetime "sent_at"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tenant_id"
    t.index ["tenant_id"], name: "index_email_logs_on_tenant_id"
  end

  create_table "export_jobs", force: :cascade do |t|
    t.string "export_type"
    t.string "file_path"
    t.string "file_name"
    t.string "content_type"
    t.integer "user_id", null: false
    t.string "status"
    t.integer "progress"
    t.integer "total_items"
    t.integer "exported_items"
    t.json "options"
    t.json "metadata"
    t.integer "tenant_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id"], name: "index_export_jobs_on_tenant_id"
    t.index ["user_id"], name: "index_export_jobs_on_user_id"
  end

  create_table "field_groups", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.text "description"
    t.integer "position", default: 0
    t.boolean "active", default: true
    t.text "location_rules"
    t.integer "tenant_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_field_groups_on_active"
    t.index ["position"], name: "index_field_groups_on_position"
    t.index ["slug"], name: "index_field_groups_on_slug"
    t.index ["tenant_id"], name: "index_field_groups_on_tenant_id"
  end

  create_table "flipper_features", force: :cascade do |t|
    t.string "key", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_flipper_features_on_key", unique: true
  end

  create_table "flipper_gates", force: :cascade do |t|
    t.string "feature_key", null: false
    t.string "key", null: false
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["feature_key", "key", "value"], name: "index_flipper_gates_on_feature_key_and_key_and_value", unique: true
  end

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.string "scope"
    t.datetime "created_at"
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_type", "sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_type_and_sluggable_id"
  end

  create_table "image_optimization_logs", force: :cascade do |t|
    t.integer "medium_id", null: false
    t.integer "upload_id", null: false
    t.integer "user_id", null: false
    t.integer "tenant_id", null: false
    t.string "filename"
    t.string "content_type"
    t.integer "original_size"
    t.integer "optimized_size"
    t.integer "width"
    t.integer "height"
    t.string "compression_level"
    t.integer "quality"
    t.boolean "strip_metadata"
    t.boolean "enable_webp"
    t.boolean "enable_avif"
    t.decimal "processing_time", precision: 10, scale: 3
    t.decimal "size_reduction_percentage", precision: 5, scale: 2
    t.integer "bytes_saved"
    t.text "variants_generated"
    t.text "responsive_variants_generated"
    t.string "optimization_type"
    t.string "status"
    t.text "error_message"
    t.text "warnings"
    t.string "storage_provider"
    t.boolean "cdn_enabled"
    t.string "user_agent"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["compression_level", "created_at"], name: "idx_on_compression_level_created_at_cd5976b03e"
    t.index ["created_at"], name: "index_image_optimization_logs_on_created_at"
    t.index ["medium_id", "created_at"], name: "index_image_optimization_logs_on_medium_id_and_created_at"
    t.index ["medium_id"], name: "index_image_optimization_logs_on_medium_id"
    t.index ["optimization_type", "created_at"], name: "idx_on_optimization_type_created_at_97990dd825"
    t.index ["status", "created_at"], name: "index_image_optimization_logs_on_status_and_created_at"
    t.index ["tenant_id", "created_at"], name: "index_image_optimization_logs_on_tenant_id_and_created_at"
    t.index ["tenant_id"], name: "index_image_optimization_logs_on_tenant_id"
    t.index ["upload_id", "created_at"], name: "index_image_optimization_logs_on_upload_id_and_created_at"
    t.index ["upload_id"], name: "index_image_optimization_logs_on_upload_id"
    t.index ["user_id", "created_at"], name: "index_image_optimization_logs_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_image_optimization_logs_on_user_id"
  end

  create_table "import_jobs", force: :cascade do |t|
    t.string "import_type"
    t.string "file_path"
    t.string "file_name"
    t.integer "user_id", null: false
    t.string "status"
    t.integer "progress"
    t.integer "total_items"
    t.integer "imported_items"
    t.integer "failed_items"
    t.text "error_log"
    t.json "metadata"
    t.integer "tenant_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id"], name: "index_import_jobs_on_tenant_id"
    t.index ["user_id"], name: "index_import_jobs_on_user_id"
  end

  create_table "media", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.string "alt_text"
    t.string "file_type"
    t.integer "file_size"
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tenant_id"
    t.integer "upload_id", null: false
    t.datetime "deleted_at"
    t.integer "trashed_by_id"
    t.index ["deleted_at"], name: "index_media_on_deleted_at"
    t.index ["tenant_id"], name: "index_media_on_tenant_id"
    t.index ["trashed_by_id"], name: "index_media_on_trashed_by_id"
    t.index ["upload_id"], name: "index_media_on_upload_id"
    t.index ["user_id"], name: "index_media_on_user_id"
  end

  create_table "menu_items", force: :cascade do |t|
    t.integer "menu_id", null: false
    t.string "label"
    t.string "url"
    t.integer "parent_id"
    t.integer "position"
    t.string "target"
    t.string "css_class"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tenant_id"
    t.index ["menu_id"], name: "index_menu_items_on_menu_id"
    t.index ["parent_id"], name: "index_menu_items_on_parent_id"
    t.index ["tenant_id"], name: "index_menu_items_on_tenant_id"
  end

  create_table "menus", force: :cascade do |t|
    t.string "name"
    t.string "location"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tenant_id"
    t.index ["tenant_id"], name: "index_menus_on_tenant_id"
  end

  create_table "meta_fields", force: :cascade do |t|
    t.string "metable_type", null: false
    t.integer "metable_id", null: false
    t.string "key", null: false
    t.text "value"
    t.boolean "immutable", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tenant_id", null: false
    t.index ["immutable"], name: "index_meta_fields_on_immutable"
    t.index ["key"], name: "index_meta_fields_on_key"
    t.index ["metable_type", "metable_id", "key"], name: "index_meta_fields_on_metable_and_key", unique: true
    t.index ["metable_type", "metable_id"], name: "index_meta_fields_on_metable"
    t.index ["tenant_id"], name: "index_meta_fields_on_tenant_id"
  end

  create_table "mobility_string_translations", force: :cascade do |t|
    t.string "locale", null: false
    t.string "key", null: false
    t.string "value"
    t.string "translatable_type"
    t.integer "translatable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["translatable_id", "translatable_type", "key"], name: "index_mobility_string_translations_on_translatable_attribute"
    t.index ["translatable_id", "translatable_type", "locale", "key"], name: "index_mobility_string_translations_on_keys", unique: true
    t.index ["translatable_type", "key", "value", "locale"], name: "index_mobility_string_translations_on_query_keys"
  end

  create_table "mobility_text_translations", force: :cascade do |t|
    t.string "locale", null: false
    t.string "key", null: false
    t.text "value"
    t.string "translatable_type"
    t.integer "translatable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["translatable_id", "translatable_type", "key"], name: "index_mobility_text_translations_on_translatable_attribute"
    t.index ["translatable_id", "translatable_type", "locale", "key"], name: "index_mobility_text_translations_on_keys", unique: true
  end

  create_table "oauth_accounts", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "tenant_id", null: false
    t.string "provider", null: false
    t.string "uid", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.string "avatar_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider", "email", "tenant_id"], name: "index_oauth_accounts_on_provider_and_email_and_tenant_id"
    t.index ["provider", "uid", "tenant_id"], name: "index_oauth_accounts_on_provider_and_uid_and_tenant_id", unique: true
    t.index ["tenant_id"], name: "index_oauth_accounts_on_tenant_id"
    t.index ["user_id"], name: "index_oauth_accounts_on_user_id"
  end

  create_table "page_templates", force: :cascade do |t|
    t.string "name", null: false
    t.string "template_type", null: false
    t.text "html_content"
    t.text "css_content"
    t.text "js_content"
    t.boolean "active", default: true
    t.integer "position", default: 0
    t.integer "tenant_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id", "active"], name: "index_page_templates_on_tenant_id_and_active"
    t.index ["tenant_id", "template_type"], name: "index_page_templates_on_tenant_id_and_template_type"
    t.index ["tenant_id"], name: "index_page_templates_on_tenant_id"
  end

  create_table "pages", force: :cascade do |t|
    t.string "title"
    t.string "slug"
    t.text "content"
    t.integer "status"
    t.integer "user_id", null: false
    t.datetime "published_at"
    t.integer "parent_id"
    t.integer "order"
    t.string "template"
    t.string "meta_description"
    t.string "meta_keywords"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tenant_id"
    t.string "meta_title"
    t.string "canonical_url"
    t.string "og_title"
    t.text "og_description"
    t.string "og_image_url"
    t.string "twitter_card", default: "summary_large_image"
    t.string "twitter_title"
    t.text "twitter_description"
    t.string "twitter_image_url"
    t.string "robots_meta", default: "index, follow"
    t.string "focus_keyphrase"
    t.string "schema_type", default: "WebPage"
    t.string "password"
    t.string "password_hint"
    t.integer "page_template_id"
    t.datetime "deleted_at"
    t.integer "trashed_by_id"
    t.index ["deleted_at"], name: "index_pages_on_deleted_at"
    t.index ["focus_keyphrase"], name: "index_pages_on_focus_keyphrase"
    t.index ["page_template_id"], name: "index_pages_on_page_template_id"
    t.index ["parent_id"], name: "index_pages_on_parent_id"
    t.index ["password"], name: "index_pages_on_password"
    t.index ["tenant_id"], name: "index_pages_on_tenant_id"
    t.index ["trashed_by_id"], name: "index_pages_on_trashed_by_id"
    t.index ["user_id"], name: "index_pages_on_user_id"
  end

  create_table "pageviews", force: :cascade do |t|
    t.string "path", null: false
    t.string "title"
    t.string "referrer"
    t.string "user_agent"
    t.string "browser"
    t.string "device"
    t.string "os"
    t.string "country_code"
    t.string "city"
    t.string "region"
    t.string "ip_hash"
    t.string "session_id"
    t.integer "user_id"
    t.integer "post_id"
    t.integer "page_id"
    t.integer "duration"
    t.boolean "unique_visitor", default: false
    t.boolean "returning_visitor", default: false
    t.boolean "bot", default: false
    t.boolean "consented", default: false
    t.text "metadata"
    t.integer "tenant_id"
    t.datetime "visited_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "reading_time"
    t.integer "scroll_depth"
    t.decimal "completion_rate"
    t.integer "time_on_page"
    t.boolean "exit_intent"
    t.string "country_name"
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.string "timezone"
    t.boolean "is_reader", default: false
    t.integer "engagement_score", default: 0
    t.index ["bot"], name: "index_pageviews_on_bot"
    t.index ["consented"], name: "index_pageviews_on_consented"
    t.index ["country_code"], name: "index_pageviews_on_country_code"
    t.index ["country_name"], name: "index_pageviews_on_country_name"
    t.index ["engagement_score"], name: "index_pageviews_on_engagement_score"
    t.index ["is_reader"], name: "index_pageviews_on_is_reader"
    t.index ["latitude", "longitude"], name: "index_pageviews_on_latitude_and_longitude"
    t.index ["page_id"], name: "index_pageviews_on_page_id"
    t.index ["path", "visited_at"], name: "index_pageviews_on_path_and_visited_at"
    t.index ["path"], name: "index_pageviews_on_path"
    t.index ["post_id"], name: "index_pageviews_on_post_id"
    t.index ["session_id"], name: "index_pageviews_on_session_id"
    t.index ["tenant_id", "visited_at"], name: "index_pageviews_on_tenant_id_and_visited_at"
    t.index ["tenant_id"], name: "index_pageviews_on_tenant_id"
    t.index ["timezone"], name: "index_pageviews_on_timezone"
    t.index ["user_id"], name: "index_pageviews_on_user_id"
    t.index ["visited_at"], name: "index_pageviews_on_visited_at"
  end

  create_table "personal_data_erasure_requests", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "email"
    t.integer "requested_by"
    t.integer "confirmed_by"
    t.string "status"
    t.string "token"
    t.text "reason"
    t.datetime "confirmed_at"
    t.datetime "completed_at"
    t.json "metadata"
    t.integer "tenant_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id"], name: "index_personal_data_erasure_requests_on_tenant_id"
    t.index ["user_id"], name: "index_personal_data_erasure_requests_on_user_id"
  end

  create_table "personal_data_export_requests", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "email"
    t.integer "requested_by"
    t.string "status"
    t.string "token"
    t.string "file_path"
    t.json "metadata"
    t.integer "tenant_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id"], name: "index_personal_data_export_requests_on_tenant_id"
    t.index ["user_id"], name: "index_personal_data_export_requests_on_user_id"
  end

  create_table "pixels", force: :cascade do |t|
    t.string "name", null: false
    t.string "pixel_type", default: "custom", null: false
    t.string "provider"
    t.string "pixel_id"
    t.text "custom_code"
    t.string "position", default: "head", null: false
    t.boolean "active", default: true
    t.text "notes"
    t.integer "tenant_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active", "position"], name: "index_pixels_on_active_and_position"
    t.index ["tenant_id"], name: "index_pixels_on_tenant_id"
  end

  create_table "plugin_settings", force: :cascade do |t|
    t.string "plugin_name", null: false
    t.string "key", null: false
    t.text "value"
    t.string "setting_type", default: "string"
    t.integer "tenant_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["plugin_name", "key"], name: "index_plugin_settings_on_plugin_name_and_key", unique: true
    t.index ["plugin_name"], name: "index_plugin_settings_on_plugin_name"
    t.index ["tenant_id"], name: "index_plugin_settings_on_tenant_id"
  end

  create_table "plugins", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "author"
    t.string "version"
    t.boolean "active"
    t.text "settings"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "posts", force: :cascade do |t|
    t.string "title"
    t.string "slug"
    t.text "content"
    t.text "excerpt"
    t.integer "status"
    t.integer "user_id", null: false
    t.datetime "published_at"
    t.string "featured_image"
    t.string "meta_description"
    t.string "meta_keywords"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tenant_id"
    t.string "meta_title"
    t.string "canonical_url"
    t.string "og_title"
    t.text "og_description"
    t.string "og_image_url"
    t.string "twitter_card", default: "summary_large_image"
    t.string "twitter_title"
    t.text "twitter_description"
    t.string "twitter_image_url"
    t.string "robots_meta", default: "index, follow"
    t.string "focus_keyphrase"
    t.string "schema_type", default: "Article"
    t.string "password"
    t.string "password_hint"
    t.datetime "deleted_at"
    t.integer "content_type_id"
    t.integer "trashed_by_id"
    t.string "template"
    t.string "comment_status", default: "open"
    t.text "content_plain"
    t.index ["content_type_id"], name: "index_posts_on_content_type_id"
    t.index ["deleted_at"], name: "index_posts_on_deleted_at"
    t.index ["focus_keyphrase"], name: "index_posts_on_focus_keyphrase"
    t.index ["password"], name: "index_posts_on_password"
    t.index ["tenant_id"], name: "index_posts_on_tenant_id"
    t.index ["trashed_by_id"], name: "index_posts_on_trashed_by_id"
    t.index ["user_id"], name: "index_posts_on_user_id"
  end

  create_table "published_theme_files", force: :cascade do |t|
    t.integer "published_theme_version_id", null: false
    t.string "file_path"
    t.string "file_type"
    t.text "content"
    t.string "checksum"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["published_theme_version_id"], name: "index_published_theme_files_on_published_theme_version_id"
  end

  create_table "published_theme_versions", force: :cascade do |t|
    t.integer "version_number"
    t.datetime "published_at"
    t.string "published_by_type", null: false
    t.integer "published_by_id", null: false
    t.integer "tenant_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "theme_id", null: false
    t.index ["published_by_type", "published_by_id"], name: "index_published_theme_versions_on_published_by"
    t.index ["tenant_id"], name: "index_published_theme_versions_on_tenant_id"
    t.index ["theme_id"], name: "index_published_theme_versions_on_theme_id"
  end

  create_table "redirects", force: :cascade do |t|
    t.string "from_path", null: false
    t.string "to_path", null: false
    t.integer "redirect_type", default: 0, null: false
    t.integer "status_code", default: 301, null: false
    t.integer "hits_count", default: 0
    t.boolean "active", default: true
    t.text "notes"
    t.integer "tenant_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["from_path", "active"], name: "index_redirects_on_from_path_and_active"
    t.index ["from_path"], name: "index_redirects_on_from_path"
    t.index ["tenant_id"], name: "index_redirects_on_tenant_id"
  end

  create_table "shortcuts", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "action_type"
    t.string "action_value"
    t.string "icon"
    t.string "category"
    t.integer "position"
    t.boolean "active"
    t.integer "tenant_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id"], name: "index_shortcuts_on_tenant_id"
  end

  create_table "site_settings", force: :cascade do |t|
    t.string "key"
    t.text "value"
    t.string "setting_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tenant_id"
    t.text "theme_development_docs"
    t.text "plugin_development_docs"
    t.boolean "docs_sync_enabled", default: false
    t.string "docs_sync_source_url"
    t.datetime "docs_last_synced_at"
    t.index ["tenant_id"], name: "index_site_settings_on_tenant_id"
  end

  create_table "slick_form_submissions", force: :cascade do |t|
    t.integer "slick_form_id", null: false
    t.json "data"
    t.string "ip_address"
    t.string "user_agent"
    t.string "referrer"
    t.boolean "spam", default: false
    t.integer "tenant_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_slick_form_submissions_on_created_at"
    t.index ["slick_form_id"], name: "index_slick_form_submissions_on_slick_form_id"
    t.index ["spam"], name: "index_slick_form_submissions_on_spam"
    t.index ["tenant_id"], name: "index_slick_form_submissions_on_tenant_id"
  end

  create_table "slick_forms", force: :cascade do |t|
    t.string "name", null: false
    t.string "title"
    t.text "description"
    t.json "fields", default: []
    t.json "settings", default: {}
    t.boolean "active", default: true
    t.integer "submissions_count", default: 0
    t.integer "tenant_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_slick_forms_on_active"
    t.index ["name"], name: "index_slick_forms_on_name"
    t.index ["tenant_id"], name: "index_slick_forms_on_tenant_id"
  end

  create_table "storage_providers", force: :cascade do |t|
    t.string "name"
    t.string "provider_type"
    t.text "config"
    t.boolean "active"
    t.integer "position"
    t.integer "tenant_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id"], name: "index_storage_providers_on_tenant_id"
  end

  create_table "subscribers", force: :cascade do |t|
    t.string "email", null: false
    t.string "name"
    t.string "status", default: "pending", null: false
    t.string "source"
    t.datetime "confirmed_at"
    t.datetime "unsubscribed_at"
    t.string "unsubscribe_token"
    t.string "ip_address"
    t.string "user_agent"
    t.text "metadata"
    t.text "tags"
    t.text "lists"
    t.integer "tenant_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_subscribers_on_email"
    t.index ["status"], name: "index_subscribers_on_status"
    t.index ["tenant_id", "email"], name: "index_subscribers_on_tenant_id_and_email", unique: true
    t.index ["tenant_id"], name: "index_subscribers_on_tenant_id"
    t.index ["unsubscribe_token"], name: "index_subscribers_on_unsubscribe_token", unique: true
  end

  create_table "taxonomies", force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.text "description"
    t.boolean "hierarchical"
    t.text "object_types"
    t.text "settings"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tenant_id"
    t.string "singular_name"
    t.string "plural_name"
    t.index ["tenant_id"], name: "index_taxonomies_on_tenant_id"
  end

  create_table "templates", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "template_type"
    t.text "html_content"
    t.text "css_content"
    t.text "js_content"
    t.integer "theme_id", null: false
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tenant_id"
    t.index ["tenant_id"], name: "index_templates_on_tenant_id"
    t.index ["theme_id"], name: "index_templates_on_theme_id"
  end

  create_table "tenants", force: :cascade do |t|
    t.string "name", null: false
    t.string "domain"
    t.string "subdomain"
    t.string "theme", default: "default"
    t.text "settings"
    t.string "locales", default: "en"
    t.boolean "active", default: true, null: false
    t.string "storage_type", default: "local"
    t.string "storage_bucket"
    t.string "storage_region"
    t.string "storage_access_key"
    t.string "storage_secret_key"
    t.string "storage_endpoint"
    t.string "storage_path"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_tenants_on_active"
    t.index ["domain"], name: "index_tenants_on_domain", unique: true
    t.index ["subdomain"], name: "index_tenants_on_subdomain", unique: true
  end

  create_table "term_relationships", force: :cascade do |t|
    t.integer "term_id", null: false
    t.string "object_type", null: false
    t.integer "object_id", null: false
    t.integer "term_order"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["object_type", "object_id"], name: "index_term_relationships_on_object"
    t.index ["term_id"], name: "index_term_relationships_on_term_id"
  end

  create_table "terms", force: :cascade do |t|
    t.integer "taxonomy_id", null: false
    t.string "name"
    t.string "slug"
    t.text "description"
    t.integer "parent_id"
    t.integer "count"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tenant_id"
    t.index ["parent_id"], name: "index_terms_on_parent_id"
    t.index ["taxonomy_id"], name: "index_terms_on_taxonomy_id"
    t.index ["tenant_id"], name: "index_terms_on_tenant_id"
  end

  create_table "theme_file_versions", force: :cascade do |t|
    t.text "content"
    t.integer "file_size"
    t.integer "user_id"
    t.string "change_summary"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_live"
    t.integer "version_number"
    t.integer "theme_version_id"
    t.integer "theme_file_id"
    t.string "file_checksum"
    t.index ["created_at"], name: "index_theme_file_versions_on_created_at"
    t.index ["theme_file_id"], name: "index_theme_file_versions_on_theme_file_id"
    t.index ["theme_version_id"], name: "index_theme_file_versions_on_theme_version_id"
    t.index ["user_id"], name: "index_theme_file_versions_on_user_id"
  end

  create_table "theme_files", force: :cascade do |t|
    t.string "theme_name"
    t.string "file_path"
    t.string "file_type"
    t.integer "current_version"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "theme_version_id"
    t.string "current_checksum"
    t.index ["theme_version_id"], name: "index_theme_files_on_theme_version_id"
  end

  create_table "theme_preview_blocks", force: :cascade do |t|
    t.integer "theme_preview_section_id", null: false
    t.string "block_type"
    t.string "block_id"
    t.text "settings"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["theme_preview_section_id"], name: "index_theme_preview_blocks_on_theme_preview_section_id"
  end

  create_table "theme_preview_files", force: :cascade do |t|
    t.integer "builder_theme_id", null: false
    t.integer "tenant_id", null: false
    t.string "file_path", null: false
    t.string "file_type", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["builder_theme_id", "file_path"], name: "index_theme_preview_files_on_builder_theme_id_and_file_path", unique: true
    t.index ["builder_theme_id"], name: "index_theme_preview_files_on_builder_theme_id"
    t.index ["file_type"], name: "index_theme_preview_files_on_file_type"
    t.index ["tenant_id"], name: "index_theme_preview_files_on_tenant_id"
  end

  create_table "theme_preview_sections", force: :cascade do |t|
    t.integer "theme_preview_id", null: false
    t.string "section_id", null: false
    t.string "section_type", null: false
    t.text "settings", null: false
    t.integer "position", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["theme_preview_id", "position"], name: "index_theme_preview_sections_on_theme_preview_id_and_position"
    t.index ["theme_preview_id", "section_id"], name: "idx_on_theme_preview_id_section_id_78607b8c4d", unique: true
    t.index ["theme_preview_id"], name: "index_theme_preview_sections_on_theme_preview_id"
  end

  create_table "theme_previews", force: :cascade do |t|
    t.integer "builder_theme_id", null: false
    t.integer "tenant_id", null: false
    t.string "template_name", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "theme_settings"
    t.json "theme_settings_json"
    t.index ["builder_theme_id", "template_name"], name: "index_theme_previews_on_builder_theme_id_and_template_name", unique: true
    t.index ["builder_theme_id"], name: "index_theme_previews_on_builder_theme_id"
    t.index ["tenant_id"], name: "index_theme_previews_on_tenant_id"
  end

  create_table "theme_version_files", force: :cascade do |t|
    t.integer "theme_version_id", null: false
    t.string "file_path"
    t.string "file_type"
    t.text "content"
    t.integer "file_size"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["theme_version_id"], name: "index_theme_version_files_on_theme_version_id"
  end

  create_table "theme_versions", force: :cascade do |t|
    t.string "theme_name"
    t.string "version"
    t.boolean "is_live"
    t.boolean "is_preview"
    t.integer "user_id", null: false
    t.text "change_summary"
    t.datetime "published_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_theme_versions_on_user_id"
  end

  create_table "themes", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "author"
    t.string "version"
    t.boolean "active"
    t.text "settings"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tenant_id"
    t.string "slug"
    t.index ["slug"], name: "index_themes_on_slug", unique: true
    t.index ["tenant_id"], name: "index_themes_on_tenant_id"
  end

  create_table "trash_settings", force: :cascade do |t|
    t.boolean "auto_cleanup_enabled"
    t.integer "cleanup_after_days"
    t.integer "tenant_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id"], name: "index_trash_settings_on_tenant_id"
  end

  create_table "upload_securities", force: :cascade do |t|
    t.integer "max_file_size"
    t.text "allowed_extensions"
    t.text "blocked_extensions"
    t.text "allowed_mime_types"
    t.text "blocked_mime_types"
    t.boolean "scan_for_viruses"
    t.boolean "quarantine_suspicious"
    t.boolean "auto_approve_trusted"
    t.integer "tenant_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id"], name: "index_upload_securities_on_tenant_id"
  end

  create_table "uploads", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "title"
    t.text "description"
    t.string "alt_text"
    t.integer "tenant_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "storage_provider_id", null: false
    t.boolean "quarantined"
    t.text "quarantine_reason"
    t.text "variants"
    t.index ["storage_provider_id"], name: "index_uploads_on_storage_provider_id"
    t.index ["tenant_id"], name: "index_uploads_on_tenant_id"
    t.index ["user_id"], name: "index_uploads_on_user_id"
  end

  create_table "user_consents", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "consent_type"
    t.text "consent_text"
    t.boolean "granted"
    t.datetime "granted_at"
    t.datetime "withdrawn_at"
    t.string "ip_address"
    t.text "user_agent"
    t.integer "tenant_id", null: false
    t.index ["tenant_id"], name: "index_user_consents_on_tenant_id"
    t.index ["user_id"], name: "index_user_consents_on_user_id"
  end

  create_table "user_notifications", force: :cascade do |t|
    t.string "plugin"
    t.integer "user_id", null: false
    t.text "message"
    t.string "notification_type"
    t.json "metadata"
    t.boolean "read"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_user_notifications_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "role"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "api_token"
    t.integer "api_requests_count"
    t.datetime "api_requests_reset_at"
    t.integer "tenant_id"
    t.string "avatar_url"
    t.text "bio"
    t.string "phone"
    t.string "location"
    t.string "website"
    t.boolean "two_factor_enabled"
    t.boolean "notification_email_enabled"
    t.boolean "notification_comment_enabled"
    t.boolean "notification_mention_enabled"
    t.string "twitter"
    t.string "github"
    t.string "linkedin"
    t.string "name"
    t.string "editor_preference", default: "blocknote"
    t.string "monaco_theme"
    t.string "api_key"
    t.text "sidebar_order"
    t.index ["api_key"], name: "index_users_on_api_key", unique: true
    t.index ["api_token"], name: "index_users_on_api_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["tenant_id"], name: "index_users_on_tenant_id"
  end

  create_table "versions", force: :cascade do |t|
    t.string "whodunnit"
    t.datetime "created_at"
    t.bigint "item_id", null: false
    t.string "item_type", null: false
    t.string "event", null: false
    t.text "object", limit: 1073741823
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  create_table "webhook_deliveries", force: :cascade do |t|
    t.integer "webhook_id", null: false
    t.string "event_type", null: false
    t.json "payload"
    t.string "status", default: "pending"
    t.integer "response_code"
    t.text "response_body"
    t.text "error_message"
    t.datetime "delivered_at"
    t.integer "retry_count", default: 0
    t.datetime "next_retry_at"
    t.string "request_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["delivered_at"], name: "index_webhook_deliveries_on_delivered_at"
    t.index ["event_type"], name: "index_webhook_deliveries_on_event_type"
    t.index ["status"], name: "index_webhook_deliveries_on_status"
    t.index ["webhook_id", "created_at"], name: "index_webhook_deliveries_on_webhook_id_and_created_at"
    t.index ["webhook_id"], name: "index_webhook_deliveries_on_webhook_id"
  end

  create_table "webhooks", force: :cascade do |t|
    t.string "url", null: false
    t.text "events"
    t.boolean "active", default: true
    t.string "secret_key", null: false
    t.string "name"
    t.text "description"
    t.integer "retry_limit", default: 3
    t.integer "timeout", default: 30
    t.datetime "last_delivered_at"
    t.integer "total_deliveries", default: 0
    t.integer "failed_deliveries", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tenant_id"
    t.index ["active"], name: "index_webhooks_on_active"
    t.index ["tenant_id"], name: "index_webhooks_on_tenant_id"
    t.index ["url"], name: "index_webhooks_on_url"
  end

  create_table "widgets", force: :cascade do |t|
    t.string "title"
    t.string "widget_type"
    t.text "content"
    t.string "sidebar_location"
    t.integer "position"
    t.text "settings"
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tenant_id"
    t.index ["tenant_id"], name: "index_widgets_on_tenant_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "ai_agents", "ai_providers"
  add_foreign_key "ai_usages", "ai_agents"
  add_foreign_key "ai_usages", "users"
  add_foreign_key "analytics_audit_logs", "tenants"
  add_foreign_key "analytics_audit_logs", "users"
  add_foreign_key "analytics_audit_logs", "users", column: "admin_user_id"
  add_foreign_key "analytics_consents", "tenants"
  add_foreign_key "analytics_consents", "users"
  add_foreign_key "analytics_data_deletions", "tenants"
  add_foreign_key "analytics_data_deletions", "users"
  add_foreign_key "analytics_data_deletions", "users", column: "admin_user_id"
  add_foreign_key "analytics_events", "tenants"
  add_foreign_key "api_tokens", "users"
  add_foreign_key "archived_analytics_events", "tenants"
  add_foreign_key "archived_analytics_events", "users"
  add_foreign_key "archived_pageviews", "pages"
  add_foreign_key "archived_pageviews", "posts"
  add_foreign_key "archived_pageviews", "tenants"
  add_foreign_key "archived_pageviews", "users"
  add_foreign_key "builder_file_settings", "builder_files"
  add_foreign_key "builder_file_settings", "tenants"
  add_foreign_key "builder_page_sections", "builder_pages"
  add_foreign_key "builder_page_sections", "tenants"
  add_foreign_key "builder_pages", "builder_themes"
  add_foreign_key "builder_pages", "tenants"
  add_foreign_key "builder_theme_files", "builder_themes"
  add_foreign_key "builder_theme_files", "tenants"
  add_foreign_key "builder_theme_sections", "builder_themes"
  add_foreign_key "builder_theme_sections", "tenants"
  add_foreign_key "builder_theme_snapshots", "builder_themes"
  add_foreign_key "builder_theme_snapshots", "tenants"
  add_foreign_key "builder_theme_snapshots", "users"
  add_foreign_key "builder_themes", "tenants"
  add_foreign_key "builder_themes", "users"
  add_foreign_key "channel_overrides", "channels"
  add_foreign_key "comments", "comments", column: "comment_parent_id"
  add_foreign_key "comments", "tenants"
  add_foreign_key "comments", "users"
  add_foreign_key "comments", "users", column: "trashed_by_id"
  add_foreign_key "consent_configurations", "tenants"
  add_foreign_key "content_types", "tenants"
  add_foreign_key "custom_field_values", "custom_fields"
  add_foreign_key "custom_field_values", "pages"
  add_foreign_key "custom_field_values", "posts"
  add_foreign_key "custom_field_values", "tenants"
  add_foreign_key "custom_fields", "field_groups"
  add_foreign_key "custom_fonts", "tenants"
  add_foreign_key "email_logs", "tenants"
  add_foreign_key "export_jobs", "tenants"
  add_foreign_key "export_jobs", "users"
  add_foreign_key "field_groups", "tenants"
  add_foreign_key "image_optimization_logs", "media"
  add_foreign_key "image_optimization_logs", "tenants"
  add_foreign_key "image_optimization_logs", "uploads"
  add_foreign_key "image_optimization_logs", "users"
  add_foreign_key "import_jobs", "tenants"
  add_foreign_key "import_jobs", "users"
  add_foreign_key "media", "tenants"
  add_foreign_key "media", "uploads"
  add_foreign_key "media", "users"
  add_foreign_key "media", "users", column: "trashed_by_id"
  add_foreign_key "menu_items", "menus"
  add_foreign_key "menu_items", "tenants"
  add_foreign_key "menus", "tenants"
  add_foreign_key "meta_fields", "tenants"
  add_foreign_key "oauth_accounts", "tenants"
  add_foreign_key "oauth_accounts", "users"
  add_foreign_key "page_templates", "tenants"
  add_foreign_key "pages", "page_templates"
  add_foreign_key "pages", "tenants"
  add_foreign_key "pages", "users"
  add_foreign_key "pages", "users", column: "trashed_by_id"
  add_foreign_key "pageviews", "pages"
  add_foreign_key "pageviews", "posts"
  add_foreign_key "pageviews", "tenants"
  add_foreign_key "pageviews", "users"
  add_foreign_key "personal_data_erasure_requests", "tenants"
  add_foreign_key "personal_data_erasure_requests", "users"
  add_foreign_key "personal_data_export_requests", "tenants"
  add_foreign_key "personal_data_export_requests", "users"
  add_foreign_key "pixels", "tenants"
  add_foreign_key "posts", "content_types"
  add_foreign_key "posts", "tenants"
  add_foreign_key "posts", "users"
  add_foreign_key "posts", "users", column: "trashed_by_id"
  add_foreign_key "published_theme_files", "published_theme_versions"
  add_foreign_key "published_theme_versions", "tenants"
  add_foreign_key "published_theme_versions", "themes"
  add_foreign_key "redirects", "tenants"
  add_foreign_key "shortcuts", "tenants"
  add_foreign_key "site_settings", "tenants"
  add_foreign_key "slick_form_submissions", "slick_forms"
  add_foreign_key "storage_providers", "tenants"
  add_foreign_key "subscribers", "tenants"
  add_foreign_key "taxonomies", "tenants"
  add_foreign_key "templates", "tenants"
  add_foreign_key "templates", "themes"
  add_foreign_key "term_relationships", "terms"
  add_foreign_key "terms", "taxonomies"
  add_foreign_key "terms", "tenants"
  add_foreign_key "theme_file_versions", "theme_files"
  add_foreign_key "theme_file_versions", "theme_versions"
  add_foreign_key "theme_file_versions", "users"
  add_foreign_key "theme_files", "theme_versions"
  add_foreign_key "theme_preview_blocks", "theme_preview_sections"
  add_foreign_key "theme_preview_files", "builder_themes"
  add_foreign_key "theme_preview_files", "tenants"
  add_foreign_key "theme_preview_sections", "theme_previews"
  add_foreign_key "theme_previews", "builder_themes"
  add_foreign_key "theme_previews", "tenants"
  add_foreign_key "theme_version_files", "theme_versions"
  add_foreign_key "theme_versions", "users"
  add_foreign_key "themes", "tenants"
  add_foreign_key "trash_settings", "tenants"
  add_foreign_key "upload_securities", "tenants"
  add_foreign_key "uploads", "storage_providers"
  add_foreign_key "uploads", "tenants"
  add_foreign_key "uploads", "users"
  add_foreign_key "user_consents", "tenants"
  add_foreign_key "user_consents", "users"
  add_foreign_key "user_notifications", "users"
  add_foreign_key "users", "tenants"
  add_foreign_key "webhook_deliveries", "webhooks"
  add_foreign_key "webhooks", "tenants"
  add_foreign_key "widgets", "tenants"
end
