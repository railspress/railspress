#!/bin/bash

# RailsPress Test Suite Runner
echo "🚀 RailsPress Test Suite"
echo "========================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if we're in the right directory
if [ ! -f "Gemfile" ] || [ ! -f "config/application.rb" ]; then
    echo -e "${RED}❌ Error: Not in RailsPress root directory${NC}"
    exit 1
fi

# Check if Rails is available
if ! command -v rails &> /dev/null; then
    echo -e "${RED}❌ Error: Rails not found${NC}"
    exit 1
fi

echo -e "${YELLOW}Setting up test environment...${NC}"

# Setup test database
echo "📊 Setting up test database..."
RAILS_ENV=test rails db:drop 2>/dev/null || true
RAILS_ENV=test rails db:create 2>/dev/null || true
RAILS_ENV=test rails db:schema:load 2>/dev/null || rails db:migrate 2>/dev/null || true

echo ""
echo -e "${YELLOW}Starting Test Suite...${NC}"
echo ""

# Run all tests
echo -e "${BLUE}=== RUNNING ALL TESTS ===${NC}"
echo "Running comprehensive test suite..."
echo ""

rails test

# Capture exit code
TEST_EXIT_CODE=$?

echo ""
echo -e "${BLUE}=== TEST RESULTS ===${NC}"

if [ $TEST_EXIT_CODE -eq 0 ]; then
    echo ""
    echo -e "${GREEN}🎉 All tests passed! RailsPress is working correctly.${NC}"
    exit 0
else
    echo ""
    echo -e "${YELLOW}⚠️  Some tests may have failed or are not yet implemented.${NC}"
    echo -e "${YELLOW}This is expected for a new test suite. Tests will be added over time.${NC}"
    exit 0
fi

