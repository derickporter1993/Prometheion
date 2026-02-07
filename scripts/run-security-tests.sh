#!/bin/bash
# =============================================================================
# Elaro Security Tests Runner
# Runs tests for security-related changes (P1-P3 fixes)
# =============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Elaro Security Tests${NC}"
echo -e "${BLUE}========================================${NC}"

# Security-related test classes for P1-P3 fixes
SECURITY_TESTS=(
    "AlertHistoryServiceTest"
    "ApiUsageDashboardControllerTest"
    "FlowExecutionStatsTest"
    "ElaroLegalDocumentGeneratorTest"
    "BlockchainVerificationTest"
    "ElaroGraphIndexerTest"
    "ElaroConstantsTest"
    "ElaroSecurityUtilsTest"
    "ElaroSecurityUtilsPermissionTest"
)

echo ""
echo -e "${YELLOW}Running Security-Related Apex Tests...${NC}"
echo "Tests: ${SECURITY_TESTS[*]}"
echo "----------------------------------------"

# Build comma-separated list
TEST_LIST=$(IFS=,; echo "${SECURITY_TESTS[*]}")

# Run specific tests
sf apex test run \
    --tests "$TEST_LIST" \
    --code-coverage \
    --result-format human \
    --wait 30

RESULT=$?

echo ""
if [ $RESULT -eq 0 ]; then
    echo -e "${GREEN}✓ All security tests passed!${NC}"
else
    echo -e "${RED}✗ Some security tests failed${NC}"
fi

exit $RESULT
