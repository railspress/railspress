FactoryBot.define do
  factory :builder_theme_file do
    path { "templates/page.liquid" }
    content { "{{ page.title }}" }
    association :builder_theme
    association :tenant
  end

  trait :liquid_file do
    path { "sections/header.liquid" }
    content { "<header>{{ page.title }}</header>" }
  end

  trait :json_file do
    path { "settings.json" }
    content { '{"name": "Test Theme"}' }
  end

  trait :css_file do
    path { "assets/style.css" }
    content { "body { margin: 0; }" }
  end

  trait :js_file do
    path { "assets/script.js" }
    content { "console.log('Hello World');" }
  end

  trait :section_file do
    path { "sections/header.liquid" }
    content { "<header>{{ page.title }}</header>" }
  end

  trait :template_file do
    path { "templates/product.json" }
    content { '{"name": "Product Template"}' }
  end

  trait :snippet_file do
    path { "snippets/navigation.liquid" }
    content { "<nav>{{ page.title }}</nav>" }
  end

  trait :layout_file do
    path { "layout/theme.liquid" }
    content { "<!DOCTYPE html><html>{{ content_for_layout }}</html>" }
  end
end
