#!/bin/bash
# =============================================================================
# Elaro Test Suite Runner
# Runs all Apex tests and Jest tests for the Elaro project
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Elaro Test Suite Runner${NC}"
echo -e "${BLUE}========================================${NC}"

# Parse arguments
RUN_APEX=true
RUN_JEST=true
VERBOSE=false

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --apex-only) RUN_JEST=false ;;
        --jest-only) RUN_APEX=false ;;
        --verbose|-v) VERBOSE=true ;;
        --help|-h)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --apex-only    Run only Apex tests"
            echo "  --jest-only    Run only Jest tests"
            echo "  --verbose, -v  Show detailed output"
            echo "  --help, -h     Show this help"
            exit 0
            ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
    shift
done

# Track results
APEX_RESULT=0
JEST_RESULT=0

# =============================================================================
# APEX TESTS
# =============================================================================
if [ "$RUN_APEX" = true ]; then
    echo ""
    echo -e "${YELLOW}Running Apex Tests...${NC}"
    echo "----------------------------------------"

    # Check if sf CLI is available
    if ! command -v sf &> /dev/null; then
        echo -e "${RED}Error: Salesforce CLI (sf) not found${NC}"
        echo "Install from: https://developer.salesforce.com/tools/salesforcecli"
        APEX_RESULT=1
    else
        # Run all Apex tests with code coverage
        if [ "$VERBOSE" = true ]; then
            sf apex test run --test-level RunLocalTests --code-coverage --result-format human --wait 30
        else
            sf apex test run --test-level RunLocalTests --code-coverage --result-format human --wait 30 2>&1 | tail -20
        fi
        APEX_RESULT=$?

        if [ $APEX_RESULT -eq 0 ]; then
            echo -e "${GREEN}✓ Apex tests passed${NC}"
        else
            echo -e "${RED}✗ Apex tests failed${NC}"
        fi
    fi
fi

# =============================================================================
# JEST TESTS
# =============================================================================
if [ "$RUN_JEST" = true ]; then
    echo ""
    echo -e "${YELLOW}Running Jest Tests...${NC}"
    echo "----------------------------------------"

    # Check if npm is available
    if ! command -v npm &> /dev/null; then
        echo -e "${RED}Error: npm not found${NC}"
        JEST_RESULT=1
    else
        # Install dependencies if needed
        if [ ! -d "node_modules" ]; then
            echo "Installing dependencies..."
            npm install
        fi

        # Run Jest tests
        if [ "$VERBOSE" = true ]; then
            npm test -- --coverage --verbose
        else
            npm test -- --coverage
        fi
        JEST_RESULT=$?

        if [ $JEST_RESULT -eq 0 ]; then
            echo -e "${GREEN}✓ Jest tests passed${NC}"
        else
            echo -e "${RED}✗ Jest tests failed${NC}"
        fi
    fi
fi

# =============================================================================
# SUMMARY
# =============================================================================
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Test Results Summary${NC}"
echo -e "${BLUE}========================================${NC}"

TOTAL_RESULT=0

if [ "$RUN_APEX" = true ]; then
    if [ $APEX_RESULT -eq 0 ]; then
        echo -e "  Apex Tests:  ${GREEN}PASSED${NC}"
    else
        echo -e "  Apex Tests:  ${RED}FAILED${NC}"
        TOTAL_RESULT=1
    fi
fi

if [ "$RUN_JEST" = true ]; then
    if [ $JEST_RESULT -eq 0 ]; then
        echo -e "  Jest Tests:  ${GREEN}PASSED${NC}"
    else
        echo -e "  Jest Tests:  ${RED}FAILED${NC}"
        TOTAL_RESULT=1
    fi
fi

echo ""
if [ $TOTAL_RESULT -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
else
    echo -e "${RED}Some tests failed. Check output above for details.${NC}"
fi

exit $TOTAL_RESULT
