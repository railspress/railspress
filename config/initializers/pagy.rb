# Pagy initializer file
# See https://ddnexus.github.io/pagy/docs/api/pagy

require 'pagy/extras/overflow'
require 'pagy/extras/metadata'

# Default configuration
Pagy::DEFAULT[:items] = 25
Pagy::DEFAULT[:max_items] = 100

# Overflow handling
Pagy::DEFAULT[:overflow] = :last_page








