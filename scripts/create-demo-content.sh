#!/bin/bash
# Create Demo Content for RailsPress
# Usage: ./scripts/create-demo-content.sh

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}✨ Creating Demo Content${NC}"
echo "========================="
echo ""

# 1. Create demo posts
echo -e "${BLUE}📝 Creating posts...${NC}"

./bin/railspress-cli post create \
  --title="Welcome to RailsPress" \
  --content="This is your first post! RailsPress is a powerful CMS built with Ruby on Rails." \
  --status=published

./bin/railspress-cli post create \
  --title="Getting Started with RailsPress" \
  --content="Learn how to use RailsPress CLI to manage your content efficiently." \
  --status=published

./bin/railspress-cli post create \
  --title="Introducing ScandiEdge Theme" \
  --content="Discover our beautiful Scandinavian-inspired theme with dark mode support." \
  --status=published

./bin/railspress-cli post create \
  --title="Building Plugins for RailsPress" \
  --content="Learn how to extend RailsPress with custom plugins and hooks." \
  --status=draft

./bin/railspress-cli post create \
  --title="Advanced Customization Tips" \
  --content="Take your RailsPress site to the next level with these advanced techniques." \
  --status=draft

# 2. Create demo pages
echo -e "${BLUE}📄 Creating pages...${NC}"

./bin/railspress-cli page create \
  --title="About Us" \
  --status=published

./bin/railspress-cli page create \
  --title="Contact" \
  --status=published

./bin/railspress-cli page create \
  --title="Privacy Policy" \
  --status=published

./bin/railspress-cli page create \
  --title="Terms of Service" \
  --status=published

# 3. Create demo users
echo -e "${BLUE}👤 Creating users...${NC}"

./bin/railspress-cli user create editor@railspress.local --role=editor 2>/dev/null || true
./bin/railspress-cli user create author@railspress.local --role=author 2>/dev/null || true
./bin/railspress-cli user create contributor@railspress.local --role=contributor 2>/dev/null || true

# 4. List created content
echo ""
echo -e "${YELLOW}📊 Content Summary:${NC}"
echo ""

echo "Posts:"
./bin/railspress-cli post list

echo ""
echo "Pages:"
./bin/railspress-cli page list

echo ""
echo "Users:"
./bin/railspress-cli user list

echo ""
echo -e "${GREEN}✓ Demo content created successfully!${NC}"
echo ""
echo "Visit http://localhost:3000 to see your demo content"
echo ""





