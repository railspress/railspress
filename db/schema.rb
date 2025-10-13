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

ActiveRecord::Schema[7.1].define(version: 2025_10_13_035846) do
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
    t.index ["ai_provider_id"], name: "index_ai_agents_on_ai_provider_id"
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

  create_table "comments", force: :cascade do |t|
    t.text "content"
    t.string "author_name"
    t.string "author_email"
    t.string "author_url"
    t.integer "status"
    t.integer "user_id", null: false
    t.string "commentable_type", null: false
    t.integer "commentable_id", null: false
    t.integer "parent_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tenant_id"
    t.index ["commentable_type", "commentable_id"], name: "index_comments_on_commentable"
    t.index ["parent_id"], name: "index_comments_on_parent_id"
    t.index ["tenant_id"], name: "index_comments_on_tenant_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
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
    t.index ["tenant_id"], name: "index_media_on_tenant_id"
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
    t.index ["deleted_at"], name: "index_pages_on_deleted_at"
    t.index ["focus_keyphrase"], name: "index_pages_on_focus_keyphrase"
    t.index ["page_template_id"], name: "index_pages_on_page_template_id"
    t.index ["parent_id"], name: "index_pages_on_parent_id"
    t.index ["password"], name: "index_pages_on_password"
    t.index ["tenant_id"], name: "index_pages_on_tenant_id"
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
    t.index ["bot"], name: "index_pageviews_on_bot"
    t.index ["consented"], name: "index_pageviews_on_consented"
    t.index ["country_code"], name: "index_pageviews_on_country_code"
    t.index ["page_id"], name: "index_pageviews_on_page_id"
    t.index ["path", "visited_at"], name: "index_pageviews_on_path_and_visited_at"
    t.index ["path"], name: "index_pageviews_on_path"
    t.index ["post_id"], name: "index_pageviews_on_post_id"
    t.index ["session_id"], name: "index_pageviews_on_session_id"
    t.index ["tenant_id", "visited_at"], name: "index_pageviews_on_tenant_id_and_visited_at"
    t.index ["tenant_id"], name: "index_pageviews_on_tenant_id"
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
    t.index ["content_type_id"], name: "index_posts_on_content_type_id"
    t.index ["deleted_at"], name: "index_posts_on_deleted_at"
    t.index ["focus_keyphrase"], name: "index_posts_on_focus_keyphrase"
    t.index ["password"], name: "index_posts_on_password"
    t.index ["tenant_id"], name: "index_posts_on_tenant_id"
    t.index ["user_id"], name: "index_posts_on_user_id"
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
    t.string "theme_name", null: false
    t.string "file_path", null: false
    t.text "content"
    t.integer "file_size"
    t.integer "user_id"
    t.string "change_summary"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_theme_file_versions_on_created_at"
    t.index ["theme_name", "file_path"], name: "index_theme_file_versions_on_theme_name_and_file_path"
    t.index ["user_id"], name: "index_theme_file_versions_on_user_id"
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
    t.index ["tenant_id"], name: "index_themes_on_tenant_id"
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
    t.index ["active"], name: "index_webhooks_on_active"
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
  add_foreign_key "api_tokens", "users"
  add_foreign_key "comments", "tenants"
  add_foreign_key "comments", "users"
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
  add_foreign_key "import_jobs", "tenants"
  add_foreign_key "import_jobs", "users"
  add_foreign_key "media", "tenants"
  add_foreign_key "media", "users"
  add_foreign_key "menu_items", "menus"
  add_foreign_key "menu_items", "tenants"
  add_foreign_key "menus", "tenants"
  add_foreign_key "page_templates", "tenants"
  add_foreign_key "pages", "page_templates"
  add_foreign_key "pages", "tenants"
  add_foreign_key "pages", "users"
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
  add_foreign_key "redirects", "tenants"
  add_foreign_key "shortcuts", "tenants"
  add_foreign_key "site_settings", "tenants"
  add_foreign_key "slick_form_submissions", "slick_forms"
  add_foreign_key "subscribers", "tenants"
  add_foreign_key "taxonomies", "tenants"
  add_foreign_key "templates", "tenants"
  add_foreign_key "templates", "themes"
  add_foreign_key "term_relationships", "terms"
  add_foreign_key "terms", "taxonomies"
  add_foreign_key "terms", "tenants"
  add_foreign_key "theme_file_versions", "users"
  add_foreign_key "themes", "tenants"
  add_foreign_key "user_notifications", "users"
  add_foreign_key "users", "tenants"
  add_foreign_key "webhook_deliveries", "webhooks"
  add_foreign_key "widgets", "tenants"
end
