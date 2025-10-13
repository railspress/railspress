#!/bin/bash
# Quick Setup Script for RailsPress
# Usage: ./scripts/quick-setup.sh

set -e  # Exit on error

echo "🚀 RailsPress Quick Setup"
echo "========================="
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if in Rails root
if [ ! -f "Gemfile" ]; then
  echo "❌ Error: Must run from Rails root directory"
  exit 1
fi

# 1. Bundle install
echo -e "${BLUE}📦 Installing dependencies...${NC}"
bundle install

# 2. Setup database
echo -e "${BLUE}💾 Setting up database...${NC}"
./bin/railspress-cli db create
./bin/railspress-cli db migrate
./bin/railspress-cli db seed

# 3. Create admin user
echo -e "${BLUE}👤 Creating admin user...${NC}"
echo "Email: admin@railspress.local"
echo "Password: railspress123"
./bin/railspress-cli user create admin@railspress.local --role=administrator --password=railspress123

# 4. Activate ScandiEdge theme
echo -e "${BLUE}🎨 Activating ScandiEdge theme...${NC}"
./bin/railspress-cli theme activate scandiedge

# 5. Configure site settings
echo -e "${BLUE}⚙️  Configuring site settings...${NC}"
./bin/railspress-cli option set site_title "RailsPress"
./bin/railspress-cli option set site_tagline "A beautiful Ruby on Rails CMS"
./bin/railspress-cli option set posts_per_page "10"

# 6. Run health check
echo -e "${BLUE}🏥 Running health check...${NC}"
./bin/railspress-cli doctor check

echo ""
echo -e "${GREEN}✓ Setup complete!${NC}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 Admin Credentials:"
echo "   Email: admin@railspress.local"
echo "   Password: railspress123"
echo ""
echo "🌐 Start the server:"
echo "   ./railspress start"
echo "   or: bin/dev"
echo ""
echo "🔗 Access the site:"
echo "   Frontend: http://localhost:3000"
echo "   Admin: http://localhost:3000/admin"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""




