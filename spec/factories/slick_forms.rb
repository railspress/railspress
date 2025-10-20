FactoryBot.define do
  factory :slick_form do
    name { "test-form" }
    title { "Test Form" }
    description { "A test form" }
    active { true }
    fields { [] }
    settings { {} }
    submissions_count { 0 }
    tenant_id { 1 }
  end

  trait :form_inactive do
    active { false }
  end

  trait :form_with_fields do
    fields { [
      { "type" => "text", "name" => "name", "label" => "Name", "required" => true },
      { "type" => "email", "name" => "email", "label" => "Email", "required" => true },
      { "type" => "textarea", "name" => "message", "label" => "Message", "required" => false }
    ] }
  end

  trait :form_with_submissions do
    submissions_count { 5 }
  end
end
