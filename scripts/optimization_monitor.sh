#!/bin/bash

# QuitTxt Optimization Implementation Monitoring Script
# This script tracks and reports on optimization implementation progress

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project paths
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TRACKING_FILE="$PROJECT_ROOT/OPTIMIZATION_TRACKING.md"
REVIEW_FILE="$PROJECT_ROOT/OPTIMIZATION_REVIEW.md"

echo -e "${BLUE}🔍 QuitTxt Optimization Implementation Monitor${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# Function to check if a file exists
check_file() {
    if [ ! -f "$1" ]; then
        echo -e "${RED}❌ File not found: $1${NC}"
        return 1
    fi
    return 0
}

# Function to run performance tests
run_performance_tests() {
    echo -e "${YELLOW}🧪 Running Performance Tests...${NC}"
    
    cd "$PROJECT_ROOT"
    
    # Run optimization performance tests
    if flutter test test/performance/optimization_tests.dart --reporter=expanded; then
        echo -e "${GREEN}✅ Performance tests completed${NC}"
        return 0
    else
        echo -e "${RED}❌ Performance tests failed${NC}"
        return 1
    fi
}

# Function to analyze code for optimization progress
analyze_optimization_progress() {
    echo -e "${YELLOW}📊 Analyzing Optimization Progress...${NC}"
    
    # Check for critical performance issues
    echo "Checking message sorting optimization..."
    if grep -q "\.sort(" "$PROJECT_ROOT/lib/providers/chat_provider.dart"; then
        echo -e "${RED}❌ Message sorting still uses full sort - Issue #1 not resolved${NC}"
    else
        echo -e "${GREEN}✅ Message sorting optimized - Issue #1 resolved${NC}"
    fi
    
    # Check Firebase initialization
    echo "Checking Firebase initialization..."
    firebase_complexity=$(grep -c "Firebase\." "$PROJECT_ROOT/lib/main.dart" || echo "0")
    if [ "$firebase_complexity" -gt 10 ]; then
        echo -e "${RED}❌ Firebase initialization still complex - Issue #2 not resolved${NC}"
    else
        echo -e "${GREEN}✅ Firebase initialization simplified - Issue #2 resolved${NC}"
    fi
    
    # Check for provider memory leaks
    echo "Checking provider disposal..."
    if grep -q "dispose()" "$PROJECT_ROOT/lib/providers/"*.dart; then
        echo -e "${GREEN}✅ Provider disposal implemented - Issue #3 progress${NC}"
    else
        echo -e "${RED}❌ Provider disposal missing - Issue #3 not resolved${NC}"
    fi
    
    # Check for performance monitoring integration
    echo "Checking performance monitoring integration..."
    if grep -q "PerformanceMonitor" "$PROJECT_ROOT/lib/providers/"*.dart; then
        echo -e "${GREEN}✅ Performance monitoring integrated${NC}"
    else
        echo -e "${YELLOW}⚠️  Performance monitoring not yet integrated${NC}"
    fi
}

# Function to run Flutter analysis
run_flutter_analysis() {
    echo -e "${YELLOW}🔍 Running Flutter Analysis...${NC}"
    
    cd "$PROJECT_ROOT"
    
    # Run Flutter analyze
    echo "Running flutter analyze..."
    if flutter analyze --no-congratulate > /tmp/flutter_analyze.log 2>&1; then
        echo -e "${GREEN}✅ No analysis issues found${NC}"
    else
        echo -e "${YELLOW}⚠️  Analysis issues found:${NC}"
        cat /tmp/flutter_analyze.log | grep -E "(error|warning)" | head -10
    fi
}

# Function to check dependency status
check_dependencies() {
    echo -e "${YELLOW}📦 Checking Dependencies...${NC}"
    
    cd "$PROJECT_ROOT"
    
    # Check for outdated packages
    echo "Checking for outdated packages..."
    outdated_count=$(flutter pub outdated --no-dependency-overrides 2>/dev/null | grep -c "✗" || echo "0")
    
    if [ "$outdated_count" -gt 0 ]; then
        echo -e "${RED}❌ $outdated_count outdated packages found - Issue #12 not resolved${NC}"
    else
        echo -e "${GREEN}✅ All packages up to date - Issue #12 resolved${NC}"
    fi
}

# Function to measure app startup time (simulation)
measure_startup_performance() {
    echo -e "${YELLOW}⏱️  Measuring Startup Performance...${NC}"
    
    # This is a simulation - in real implementation, this would measure actual startup time
    # For now, we'll check if performance monitoring is in place
    
    if [ -f "$PROJECT_ROOT/lib/utils/performance_monitor.dart" ]; then
        echo -e "${GREEN}✅ Performance monitoring tools available${NC}"
        echo "📊 Baseline measurements can now be taken"
    else
        echo -e "${RED}❌ Performance monitoring tools not found${NC}"
    fi
}

# Function to generate progress report
generate_progress_report() {
    echo -e "${YELLOW}📋 Generating Progress Report...${NC}"
    
    local report_file="$PROJECT_ROOT/OPTIMIZATION_PROGRESS_REPORT.md"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    cat > "$report_file" << EOF
# QuitTxt Optimization Progress Report

**Generated**: $timestamp  
**Script Version**: 1.0

## 🎯 Critical Issues Status

### Issue #1: Message Sorting Algorithm
- **Status**: $(grep -q "\.sort(" "$PROJECT_ROOT/lib/providers/chat_provider.dart" && echo "🔴 Not Resolved" || echo "✅ Resolved")
- **File**: lib/providers/chat_provider.dart
- **Impact**: High Performance Impact

### Issue #2: Firebase Initialization
- **Status**: $([ $(grep -c "Firebase\." "$PROJECT_ROOT/lib/main.dart" || echo "0") -gt 10 ] && echo "🔴 Not Resolved" || echo "✅ Resolved")
- **File**: lib/main.dart
- **Impact**: Startup Performance

### Issue #3: Provider Memory Leaks
- **Status**: $(grep -q "dispose()" "$PROJECT_ROOT/lib/providers/"*.dart && echo "🟡 In Progress" || echo "🔴 Not Started")
- **Files**: lib/providers/*.dart
- **Impact**: Memory Management

## 🧪 Test Results

### Performance Tests
- **Status**: $(flutter test test/performance/optimization_tests.dart >/dev/null 2>&1 && echo "✅ Passing" || echo "❌ Failing")
- **Location**: test/performance/optimization_tests.dart

### Static Analysis
- **Issues Found**: $(flutter analyze --no-congratulate 2>&1 | grep -c "issues found" || echo "0")
- **Status**: $(flutter analyze >/dev/null 2>&1 && echo "✅ Clean" || echo "⚠️ Issues Found")

## 📦 Dependencies

### Outdated Packages
- **Count**: $(flutter pub outdated --no-dependency-overrides 2>/dev/null | grep -c "✗" || echo "0")
- **Target**: 0 outdated packages

## 📊 Performance Monitoring

### Monitoring Tools
- **Performance Monitor**: $([ -f "$PROJECT_ROOT/lib/utils/performance_monitor.dart" ] && echo "✅ Available" || echo "❌ Missing")
- **Optimization Tests**: $([ -f "$PROJECT_ROOT/test/performance/optimization_tests.dart" ] && echo "✅ Available" || echo "❌ Missing")
- **Tracking System**: $([ -f "$PROJECT_ROOT/OPTIMIZATION_TRACKING.md" ] && echo "✅ Available" || echo "❌ Missing")

## 🎯 Next Actions

1. **Immediate**: Implement message sorting optimization
2. **Short Term**: Simplify Firebase initialization
3. **Medium Term**: Add provider disposal management
4. **Long Term**: Complete all 14 optimization issues

---

*Report generated by optimization_monitor.sh*
EOF

    echo -e "${GREEN}✅ Progress report generated: $report_file${NC}"
}

# Function to update tracking file
update_tracking_file() {
    echo -e "${YELLOW}📝 Updating Tracking File...${NC}"
    
    if check_file "$TRACKING_FILE"; then
        # Update last updated timestamp
        local timestamp=$(date '+%Y-%m-%d')
        sed -i.bak "s/\*\*Last Updated\*\*: .*/\*\*Last Updated\*\*: $timestamp/" "$TRACKING_FILE"
        echo -e "${GREEN}✅ Tracking file updated${NC}"
    fi
}

# Main execution flow
main() {
    echo "Starting optimization monitoring..."
    echo "Project root: $PROJECT_ROOT"
    echo ""
    
    # Check required files exist
    check_file "$TRACKING_FILE" || exit 1
    check_file "$REVIEW_FILE" || exit 1
    
    # Run analysis
    analyze_optimization_progress
    echo ""
    
    # Run Flutter analysis
    run_flutter_analysis
    echo ""
    
    # Check dependencies
    check_dependencies
    echo ""
    
    # Measure performance
    measure_startup_performance
    echo ""
    
    # Run performance tests (optional, may fail initially)
    if [ "${1:-}" == "--with-tests" ]; then
        run_performance_tests || echo -e "${YELLOW}⚠️  Performance tests failed (expected during early implementation)${NC}"
        echo ""
    fi
    
    # Generate progress report
    generate_progress_report
    echo ""
    
    # Update tracking file
    update_tracking_file
    echo ""
    
    echo -e "${GREEN}🎉 Optimization monitoring completed${NC}"
    echo -e "${BLUE}📋 Check OPTIMIZATION_PROGRESS_REPORT.md for detailed results${NC}"
}

# Run main function with all arguments
main "$@"