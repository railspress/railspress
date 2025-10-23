# Pin npm packages by running ./bin/importmap

pin "application"

pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus",    to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true

pin "@rails/actiontext", to: "actiontext.esm.js"
pin "@rails/actioncable", to: "actioncable.esm.js"

pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from "app/javascript/channels", under: "channels"

pin "editorjs_converter", to: "editorjs_converter.js"

pin "trix"

pin "tabulator-tables", to: "https://cdn.jsdelivr.net/npm/tabulator-tables@6.2.1/dist/js/tabulator_esm.min.js"

# Admin table configurations
pin "admin_table_columns", to: "admin_table_columns.js"

# Shopify Draggable
pin "@shopify/draggable", to: "@shopify--draggable.js" # @1.1.4

# Chart.js for professional analytics
pin "chart.js/auto", to: "https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"
pin "chartjs-adapter-date-fns", to: "https://cdn.jsdelivr.net/npm/chartjs-adapter-date-fns@3.0.0/dist/chartjs-adapter-date-fns.bundle.min.js"

