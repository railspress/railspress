#!/bin/bash
# Backup Script for RailsPress
# Usage: ./scripts/backup.sh [backup_name]

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

BACKUP_DIR="backups"
BACKUP_NAME=${1:-"backup-$(date +%Y%m%d-%H%M%S)"}
BACKUP_PATH="$BACKUP_DIR/$BACKUP_NAME"

echo -e "${BLUE}📦 RailsPress Backup${NC}"
echo "====================="
echo ""

# Create backup directory
mkdir -p "$BACKUP_DIR"
mkdir -p "$BACKUP_PATH"

# 1. Export database
echo -e "${BLUE}💾 Exporting database...${NC}"
if [ "$RAILS_ENV" == "production" ]; then
  PGPASSWORD=$DATABASE_PASSWORD pg_dump -h $DATABASE_HOST -U $DATABASE_USER $DATABASE_NAME > "$BACKUP_PATH/database.sql"
else
  cp db/development.sqlite3 "$BACKUP_PATH/database.sqlite3" 2>/dev/null || echo "SQLite database not found"
fi

# 2. Export users
echo -e "${BLUE}👤 Exporting users...${NC}"
./bin/railspress-cli user list --format=json > "$BACKUP_PATH/users.json"

# 3. Export posts
echo -e "${BLUE}📝 Exporting posts...${NC}"
./bin/railspress-cli post list --format=json > "$BACKUP_PATH/posts.json"

# 4. Export pages
echo -e "${BLUE}📄 Exporting pages...${NC}"
./bin/railspress-cli page list --format=json > "$BACKUP_PATH/pages.json"

# 5. Export settings
echo -e "${BLUE}⚙️  Exporting settings...${NC}"
./bin/railspress-cli option list --format=json > "$BACKUP_PATH/settings.json"

# 6. Copy uploads (if exists)
if [ -d "storage" ]; then
  echo -e "${BLUE}📁 Copying uploads...${NC}"
  cp -r storage "$BACKUP_PATH/storage"
fi

# 7. Create metadata
echo -e "${BLUE}📋 Creating metadata...${NC}"
cat > "$BACKUP_PATH/metadata.json" << EOF
{
  "backup_date": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "rails_version": "$(rails -v)",
  "ruby_version": "$(ruby -v)",
  "environment": "${RAILS_ENV:-development}"
}
EOF

# 8. Compress backup
echo -e "${BLUE}🗜️  Compressing backup...${NC}"
tar -czf "$BACKUP_PATH.tar.gz" -C "$BACKUP_DIR" "$BACKUP_NAME"
rm -rf "$BACKUP_PATH"

echo ""
echo -e "${GREEN}✓ Backup complete!${NC}"
echo ""
echo "📦 Backup saved to: $BACKUP_PATH.tar.gz"
echo "📊 Backup size: $(du -h "$BACKUP_PATH.tar.gz" | cut -f1)"
echo ""





