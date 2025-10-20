FactoryBot.define do
  factory :builder_theme_section do
    section_id { "section_#{SecureRandom.hex(4)}" }
    section_type { "header" }
    position { 0 }
    settings { {} }
    association :builder_theme
    association :tenant
  end

  trait :header_section do
    section_type { "header" }
    settings { { "title" => "Header Section", "background_color" => "#ffffff" } }
  end

  trait :footer_section do
    section_type { "footer" }
    settings { { "title" => "Footer Section", "background_color" => "#333333" } }
  end

  trait :content_section do
    section_type { "content" }
    settings { { "title" => "Content Section", "columns" => 2 } }
  end

  trait :sidebar_section do
    section_type { "sidebar" }
    settings { { "title" => "Sidebar Section", "position" => "right" } }
  end
end
