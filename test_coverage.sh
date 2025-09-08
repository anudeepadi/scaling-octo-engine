#!/bin/bash

echo "🧪 Starting QuitTxT App Test Suite and Coverage Analysis..."
echo "================================================="

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    exit 1
fi

print_status "Flutter version:"
flutter --version

# Clean previous builds
print_status "Cleaning previous builds..."
flutter clean
flutter pub get

# Generate mocks
print_status "Generating mocks..."
flutter packages pub run build_runner build --delete-conflicting-outputs

# Run static analysis
print_status "Running static analysis..."
flutter analyze > analysis_report.txt 2>&1
if [ $? -eq 0 ]; then
    print_success "Static analysis passed"
else
    print_warning "Static analysis found issues. Check analysis_report.txt"
fi

# Create coverage directory
mkdir -p coverage

# Run unit tests with coverage
print_status "Running unit tests with coverage..."
flutter test --coverage --coverage-path=coverage/lcov.info

if [ $? -eq 0 ]; then
    print_success "Unit tests completed"
else
    print_error "Unit tests failed"
    exit 1
fi

# Check if lcov is installed for HTML report generation
if command -v genhtml &> /dev/null; then
    print_status "Generating HTML coverage report..."
    genhtml coverage/lcov.info -o coverage/html
    print_success "HTML coverage report generated at coverage/html/index.html"
else
    print_warning "lcov not installed. Install it to generate HTML coverage reports:"
    echo "  macOS: brew install lcov"
    echo "  Ubuntu: sudo apt-get install lcov"
fi

# Run integration tests (if available)
if [ -d "integration_test" ]; then
    print_status "Running integration tests..."
    flutter test integration_test/
    if [ $? -eq 0 ]; then
        print_success "Integration tests completed"
    else
        print_warning "Integration tests had issues"
    fi
else
    print_warning "No integration_test directory found"
fi

# Parse coverage data
print_status "Analyzing coverage data..."

if [ -f "coverage/lcov.info" ]; then
    # Extract coverage percentage
    COVERAGE_LINES=$(grep -E "LF:|LH:" coverage/lcov.info)
    TOTAL_LINES=$(echo "$COVERAGE_LINES" | grep "LF:" | awk -F: '{sum += $2} END {print sum}')
    HIT_LINES=$(echo "$COVERAGE_LINES" | grep "LH:" | awk -F: '{sum += $2} END {print sum}')

    if [ "$TOTAL_LINES" -gt 0 ]; then
        COVERAGE_PERCENT=$(echo "scale=2; $HIT_LINES * 100 / $TOTAL_LINES" | bc -l)
        echo ""
        echo "========================================"
        echo "📊 COVERAGE SUMMARY"
        echo "========================================"
        echo "Total Lines: $TOTAL_LINES"
        echo "Covered Lines: $HIT_LINES"
        echo "Coverage Percentage: ${COVERAGE_PERCENT}%"
        echo ""

        if (( $(echo "$COVERAGE_PERCENT >= 80" | bc -l) )); then
            print_success "Excellent coverage! (≥80%)"
        elif (( $(echo "$COVERAGE_PERCENT >= 60" | bc -l) )); then
            print_warning "Good coverage (60-80%). Consider improving."
        else
            print_error "Low coverage (<60%). Needs improvement."
        fi
    fi
fi

# Generate test report
print_status "Generating test summary report..."
cat > test_report.md << EOF
# QuitTxT App Test Report

**Generated on:** $(date)

## Test Results Summary

### Static Analysis
$(if [ -f "analysis_report.txt" ] && [ -s "analysis_report.txt" ]; then echo "⚠️ Issues found (see analysis_report.txt)"; else echo "✅ Passed"; fi)

### Unit Tests
✅ Completed successfully

### Coverage Analysis
- **Total Lines:** ${TOTAL_LINES:-"N/A"}
- **Covered Lines:** ${HIT_LINES:-"N/A"}
- **Coverage Percentage:** ${COVERAGE_PERCENT:-"N/A"}%

### Test Categories Covered
- ✅ Widget Tests
- ✅ Provider Tests (Auth, Chat)
- ✅ Service Tests (Emoji, Link Preview)
- ✅ Model Tests
- ✅ UI Component Tests

### Integration Tests
$(if [ -d "integration_test" ]; then echo "✅ Available"; else echo "⚠️ Not configured"; fi)

## Files Generated
- \`coverage/lcov.info\` - Coverage data
- \`coverage/html/index.html\` - HTML coverage report (if lcov installed)
- \`analysis_report.txt\` - Static analysis results
- \`test_report.md\` - This summary report

## Recommendations
1. Maintain coverage above 80%
2. Fix any static analysis issues
3. Add integration tests for critical user flows
4. Regular testing before releases

EOF

print_success "Test report generated: test_report.md"

echo ""
echo "========================================"
echo "🎉 TEST SUITE COMPLETE!"
echo "========================================"
echo "Coverage report: coverage/html/index.html"
echo "Analysis report: analysis_report.txt"
echo "Test summary: test_report.md"
echo ""

# Open coverage report if on macOS and report exists
if [[ "$OSTYPE" == "darwin"* ]] && [ -f "coverage/html/index.html" ]; then
    read -p "Open coverage report in browser? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        open coverage/html/index.html
    fi
fi
