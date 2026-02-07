#!/bin/bash
# =============================================================================
# Elaro Jest Test Runner
# Runs LWC Jest tests with various options
# =============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Elaro Jest Test Runner${NC}"
echo -e "${BLUE}========================================${NC}"

# Parse arguments
COVERAGE=false
WATCH=false
COMPONENT=""
VERBOSE=false

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --coverage|-c) COVERAGE=true ;;
        --watch|-w) WATCH=true ;;
        --component) COMPONENT="$2"; shift ;;
        --verbose|-v) VERBOSE=true ;;
        --help|-h)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --coverage, -c     Run with coverage report"
            echo "  --watch, -w        Run in watch mode"
            echo "  --component NAME   Run tests for specific component"
            echo "  --verbose, -v      Show detailed output"
            echo "  --help, -h         Show this help"
            echo ""
            echo "Examples:"
            echo "  $0 --coverage"
            echo "  $0 --component apiUsageDashboard"
            echo "  $0 --watch --component complianceDashboard"
            exit 0
            ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
    shift
done

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}Installing dependencies...${NC}"
    npm install
fi

# Build command
CMD="npm test --"

if [ "$COVERAGE" = true ]; then
    CMD="$CMD --coverage"
fi

if [ "$WATCH" = true ]; then
    CMD="$CMD --watch"
fi

if [ "$VERBOSE" = true ]; then
    CMD="$CMD --verbose"
fi

if [ -n "$COMPONENT" ]; then
    CMD="$CMD --testPathPattern=$COMPONENT"
fi

echo ""
echo -e "${YELLOW}Running: $CMD${NC}"
echo "----------------------------------------"

eval $CMD
RESULT=$?

if [ $RESULT -eq 0 ]; then
    echo -e "${GREEN}✓ Jest tests passed!${NC}"
else
    echo -e "${RED}✗ Jest tests failed${NC}"
fi

exit $RESULT
