#!/bin/bash

# RailsPress Storage System Test Runner
# Runs all tests related to storage settings and upload functionality

echo "🧪 Running RailsPress Storage System Tests"
echo "=========================================="

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test results
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Function to run tests and capture results
run_test_suite() {
    local test_name="$1"
    local test_path="$2"
    
    echo -e "\n${BLUE}Running $test_name...${NC}"
    echo "----------------------------------------"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if bundle exec rspec "$test_path" --format documentation; then
        echo -e "${GREEN}✅ $test_name PASSED${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}❌ $test_name FAILED${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
}

# Check if we're in the right directory
if [ ! -f "Gemfile" ] || [ ! -d "spec" ]; then
    echo -e "${RED}Error: Please run this script from the RailsPress root directory${NC}"
    exit 1
fi

# Check if RSpec is available
if ! command -v bundle &> /dev/null; then
    echo -e "${RED}Error: Bundler not found. Please install bundler first.${NC}"
    exit 1
fi

# Install dependencies if needed
echo -e "${YELLOW}Checking dependencies...${NC}"
bundle check || bundle install

echo -e "\n${BLUE}Starting Storage System Test Suite${NC}"
echo "=========================================="

# Run individual test suites
run_test_suite "StorageConfigurationService Tests" "spec/services/storage_configuration_service_spec.rb"
run_test_suite "UploadSecurity Integration Tests" "spec/models/upload_security_spec.rb"
run_test_suite "Upload Model Tests" "spec/models/upload_spec.rb"
run_test_suite "Settings Controller Tests" "spec/controllers/admin/settings_controller_spec.rb"
run_test_suite "Storage Integration Tests" "spec/requests/storage_settings_integration_spec.rb"

# Run all storage-related tests together
echo -e "\n${BLUE}Running All Storage Tests Together...${NC}"
echo "=========================================="

TOTAL_TESTS=$((TOTAL_TESTS + 1))
if bundle exec rspec spec/services/storage_configuration_service_spec.rb spec/models/upload_security_spec.rb spec/models/upload_spec.rb spec/controllers/admin/settings_controller_spec.rb spec/requests/storage_settings_integration_spec.rb --format progress; then
    echo -e "${GREEN}✅ All Storage Tests PASSED${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    echo -e "${RED}❌ Some Storage Tests FAILED${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi

# Summary
echo -e "\n${BLUE}Test Summary${NC}"
echo "============"
echo -e "Total Test Suites: ${TOTAL_TESTS}"
echo -e "${GREEN}Passed: ${PASSED_TESTS}${NC}"
echo -e "${RED}Failed: ${FAILED_TESTS}${NC}"

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "\n${GREEN}🎉 All storage system tests passed!${NC}"
    echo -e "${GREEN}The storage settings and upload system are working correctly.${NC}"
    exit 0
else
    echo -e "\n${RED}💥 Some tests failed. Please check the output above for details.${NC}"
    echo -e "${YELLOW}You may need to:${NC}"
    echo -e "  - Check that all required factories exist"
    echo -e "  - Verify database migrations are up to date"
    echo -e "  - Ensure all dependencies are installed"
    echo -e "  - Check for any missing test fixtures"
    exit 1
fi
