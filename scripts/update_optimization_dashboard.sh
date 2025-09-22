#!/bin/bash

# QuitTxt Optimization Dashboard Update Script
# Automatically updates dashboard with current progress and metrics

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project paths
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DASHBOARD_FILE="$PROJECT_ROOT/OPTIMIZATION_DASHBOARD.md"
TRACKER_FILE="$PROJECT_ROOT/OPTIMIZATION_TRACKING.md"

echo -e "${BLUE}🔄 Updating QuitTxt Optimization Dashboard${NC}"
echo -e "${BLUE}===========================================${NC}"
echo ""

# Function to get current timestamp
get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Function to analyze code for task completion
analyze_task_completion() {
    echo -e "${YELLOW}📊 Analyzing task completion status...${NC}"
    
    local completed_tasks=0
    local total_tasks=14
    
    # Check Issue #1: Message Sorting Algorithm
    if ! grep -q "\.sort(" "$PROJECT_ROOT/lib/providers/chat_provider.dart" 2>/dev/null; then
        echo "✅ Issue #1: Message sorting optimized"
        ((completed_tasks++))
    else
        echo "🔴 Issue #1: Message sorting not optimized"
    fi
    
    # Check Issue #2: Firebase Initialization
    firebase_complexity=$(grep -c "Firebase\." "$PROJECT_ROOT/lib/main.dart" 2>/dev/null || echo "0")
    if [ "$firebase_complexity" -le 5 ]; then
        echo "✅ Issue #2: Firebase initialization simplified"
        ((completed_tasks++))
    else
        echo "🔴 Issue #2: Firebase initialization still complex"
    fi
    
    # Check Issue #3: Provider Memory Leaks
    if grep -q "dispose()" "$PROJECT_ROOT/lib/providers/"*.dart 2>/dev/null; then
        echo "✅ Issue #3: Provider disposal implemented"
        ((completed_tasks++))
    else
        echo "🔴 Issue #3: Provider disposal missing"
    fi
    
    # Check Issue #4: Provider Over-Coupling
    if grep -q "setChatProvider" "$PROJECT_ROOT/lib/providers/dash_chat_provider.dart" 2>/dev/null; then
        echo "🔴 Issue #4: Provider coupling still exists"
    else
        echo "✅ Issue #4: Provider coupling resolved"
        ((completed_tasks++))
    fi
    
    # Check Issue #5: Message Processing
    if grep -q "compute(" "$PROJECT_ROOT/lib/providers/chat_provider.dart" 2>/dev/null; then
        echo "✅ Issue #5: Async message processing implemented"
        ((completed_tasks++))
    else
        echo "🔴 Issue #5: Message processing still blocks UI"
    fi
    
    # Check Issue #6: State Updates
    if grep -q "notifyListeners.*batch" "$PROJECT_ROOT/lib/providers/"*.dart 2>/dev/null; then
        echo "✅ Issue #6: State update batching implemented"
        ((completed_tasks++))
    else
        echo "🔴 Issue #6: State updates not batched"
    fi
    
    # Check Issue #7: Firestore Queries
    if grep -q "offline.*persistence" "$PROJECT_ROOT/lib/services/"*.dart 2>/dev/null; then
        echo "✅ Issue #7: Firestore optimization implemented"
        ((completed_tasks++))
    else
        echo "🔴 Issue #7: Firestore queries not optimized"
    fi
    
    # Check Issue #8: FCM Token Management
    if grep -q "token.*cache" "$PROJECT_ROOT/lib/services/firebase_messaging_service.dart" 2>/dev/null; then
        echo "✅ Issue #8: FCM token caching implemented"
        ((completed_tasks++))
    else
        echo "🔴 Issue #8: FCM token management not optimized"
    fi
    
    # Check Issue #9: List Rendering
    if grep -q "AutomaticKeepAliveClientMixin" "$PROJECT_ROOT/lib/widgets/chat_message_widget.dart" 2>/dev/null; then
        echo "✅ Issue #9: List rendering optimized"
        ((completed_tasks++))
    else
        echo "🔴 Issue #9: List rendering not optimized"
    fi
    
    # Check Issue #10: Widget Keys
    if grep -q "ValueKey\|ObjectKey" "$PROJECT_ROOT/lib/widgets/"*.dart 2>/dev/null; then
        echo "✅ Issue #10: Widget keys implemented"
        ((completed_tasks++))
    else
        echo "🔴 Issue #10: Widget keys missing"
    fi
    
    # Check Issue #11: iOS Performance
    ios_lines=$(wc -l < "$PROJECT_ROOT/lib/utils/ios_performance_utils.dart" 2>/dev/null || echo "0")
    if [ "$ios_lines" -lt 50 ]; then
        echo "✅ Issue #11: iOS performance utils optimized"
        ((completed_tasks++))
    else
        echo "🔴 Issue #11: iOS performance utils not optimized"
    fi
    
    # Check Issue #12: Dependencies (already completed)
    outdated_count=$(flutter pub outdated --no-dependency-overrides 2>/dev/null | grep -c "✗" || echo "0")
    if [ "$outdated_count" -eq 0 ]; then
        echo "✅ Issue #12: Dependencies up to date"
        ((completed_tasks++))
    else
        echo "🔴 Issue #12: $outdated_count outdated dependencies"
    fi
    
    # Check Issue #13: Image Caching
    if grep -q "memCacheWidth\|memCacheHeight" "$PROJECT_ROOT/lib/"**/*.dart 2>/dev/null; then
        echo "✅ Issue #13: Image caching configured"
        ((completed_tasks++))
    else
        echo "🔴 Issue #13: Image caching not configured"
    fi
    
    # Check Issue #14: Service Singletons
    if grep -q "GetIt\|get_it" "$PROJECT_ROOT/pubspec.yaml" 2>/dev/null; then
        echo "✅ Issue #14: Service locator implemented"
        ((completed_tasks++))
    else
        echo "🔴 Issue #14: Service locator not implemented"
    fi
    
    local progress_percent=$((completed_tasks * 100 / total_tasks))
    echo ""
    echo -e "${GREEN}📊 Overall Progress: $completed_tasks/$total_tasks ($progress_percent%)${NC}"
    
    # Return progress for use in dashboard update
    echo "$progress_percent" > /tmp/optimization_progress.txt
    echo "$completed_tasks" > /tmp/completed_tasks.txt
}

# Function to update dashboard metrics
update_dashboard_metrics() {
    echo -e "${YELLOW}📝 Updating dashboard metrics...${NC}"
    
    local timestamp=$(get_timestamp)
    local progress=$(cat /tmp/optimization_progress.txt 2>/dev/null || echo "0")
    local completed=$(cat /tmp/completed_tasks.txt 2>/dev/null || echo "0")
    
    # Update the main dashboard file
    if [ -f "$DASHBOARD_FILE" ]; then
        # Update last updated timestamp
        sed -i.bak "s/\*\*Last Updated\*\*: .*/\*\*Last Updated\*\*: $timestamp/" "$DASHBOARD_FILE"
        
        # Update overall progress
        sed -i.bak "s/\*\*Overall Progress\*\*: [0-9]*\/14 ([0-9]*%)/\*\*Overall Progress\*\*: $completed\/14 ($progress%)/" "$DASHBOARD_FILE"
        
        # Update progress status
        if [ "$progress" -eq 0 ]; then
            sed -i.bak "s/| \*\*Overall Progress\*\* | [0-9]*% | 100% | .* |/| \*\*Overall Progress\*\* | $progress% | 100% | 🔴 Not Started |/" "$DASHBOARD_FILE"
        elif [ "$progress" -lt 50 ]; then
            sed -i.bak "s/| \*\*Overall Progress\*\* | [0-9]*% | 100% | .* |/| \*\*Overall Progress\*\* | $progress% | 100% | 🟡 In Progress |/" "$DASHBOARD_FILE"
        elif [ "$progress" -lt 100 ]; then
            sed -i.bak "s/| \*\*Overall Progress\*\* | [0-9]*% | 100% | .* |/| \*\*Overall Progress\*\* | $progress% | 100% | 🟡 In Progress |/" "$DASHBOARD_FILE"
        else
            sed -i.bak "s/| \*\*Overall Progress\*\* | [0-9]*% | 100% | .* |/| \*\*Overall Progress\*\* | $progress% | 100% | 🟢 Complete |/" "$DASHBOARD_FILE"
        fi
        
        echo "✅ Dashboard metrics updated"
    else
        echo "❌ Dashboard file not found: $DASHBOARD_FILE"
    fi
}

# Function to run performance measurements
measure_performance() {
    echo -e "${YELLOW}⏱️  Running performance measurements...${NC}"
    
    cd "$PROJECT_ROOT"
    
    # Run Flutter analyze to get code quality metrics
    echo "Running Flutter analyze..."
    local analyze_result
    if analyze_result=$(flutter analyze --no-congratulate 2>&1); then
        local warning_count=$(echo "$analyze_result" | grep -c "warning" || echo "0")
        local error_count=$(echo "$analyze_result" | grep -c "error" || echo "0")
        echo "Code quality: $error_count errors, $warning_count warnings"
    else
        echo "Flutter analyze failed"
    fi
    
    # Check if performance tests exist and run them
    if [ -f "test/performance/optimization_tests.dart" ]; then
        echo "Running performance tests..."
        if flutter test test/performance/optimization_tests.dart --reporter=json > /tmp/performance_results.json 2>/dev/null; then
            echo "✅ Performance tests completed"
        else
            echo "⚠️  Performance tests failed (expected during development)"
        fi
    else
        echo "Performance tests not found"
    fi
    
    # Measure app size
    if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
        local app_size=$(du -h "build/app/outputs/flutter-apk/app-release.apk" | cut -f1)
        echo "App size: $app_size"
    else
        echo "Release APK not found"
    fi
}

# Function to update task statuses based on code analysis
update_task_statuses() {
    echo -e "${YELLOW}📋 Updating individual task statuses...${NC}"
    
    # This would integrate with the OptimizationTracker to update task statuses
    # For now, we'll just log the status updates that would be made
    
    echo "Task status updates that would be applied:"
    
    # Check each critical task
    if ! grep -q "\.sort(" "$PROJECT_ROOT/lib/providers/chat_provider.dart" 2>/dev/null; then
        echo "- Task opt-001 (Message Sorting): NOT STARTED → COMPLETED"
    fi
    
    if grep -q "dispose()" "$PROJECT_ROOT/lib/providers/"*.dart 2>/dev/null; then
        echo "- Task opt-003 (Provider Memory): NOT STARTED → IN PROGRESS"
    fi
    
    # In a real implementation, this would call:
    # flutter run --dart-define=UPDATE_TASK_STATUS=true
    # Or use a more sophisticated integration
}

# Function to generate status report
generate_status_report() {
    echo -e "${YELLOW}📊 Generating status report...${NC}"
    
    local timestamp=$(get_timestamp)
    local progress=$(cat /tmp/optimization_progress.txt 2>/dev/null || echo "0")
    local completed=$(cat /tmp/completed_tasks.txt 2>/dev/null || echo "0")
    
    local report_file="$PROJECT_ROOT/OPTIMIZATION_STATUS_REPORT.md"
    
    cat > "$report_file" << EOF
# QuitTxt Optimization Status Report

**Generated**: $timestamp  
**Script**: update_optimization_dashboard.sh  
**Overall Progress**: $completed/14 tasks ($progress%)

## 📊 Executive Summary

| Metric | Value | Status |
|--------|-------|--------|
| Total Tasks | 14 | 📋 Defined |
| Completed Tasks | $completed | $([ "$completed" -gt 0 ] && echo "✅" || echo "🔴") $([ "$completed" -gt 0 ] && echo "Progress" || echo "Not Started") |
| Overall Progress | $progress% | $([ "$progress" -ge 50 ] && echo "🟡" || echo "🔴") $([ "$progress" -ge 50 ] && echo "In Progress" || echo "Behind") |
| Critical Issues Resolved | $([ "$completed" -ge 3 ] && echo "3/3" || echo "$completed/3") | $([ "$completed" -ge 3 ] && echo "✅ Complete" || echo "🔴 Pending") |

## 🚨 Critical Issues Status

EOF

    # Add detailed task analysis
    echo "### Message Sorting Algorithm (opt-001)" >> "$report_file"
    if ! grep -q "\.sort(" "$PROJECT_ROOT/lib/providers/chat_provider.dart" 2>/dev/null; then
        echo "- **Status**: ✅ COMPLETED" >> "$report_file"
        echo "- **Analysis**: No .sort() calls found in chat_provider.dart" >> "$report_file"
    else
        echo "- **Status**: 🔴 NOT STARTED" >> "$report_file"
        echo "- **Analysis**: .sort() calls still present in chat_provider.dart" >> "$report_file"
    fi
    echo "" >> "$report_file"
    
    echo "### Firebase Initialization (opt-002)" >> "$report_file"
    local firebase_complexity=$(grep -c "Firebase\." "$PROJECT_ROOT/lib/main.dart" 2>/dev/null || echo "0")
    if [ "$firebase_complexity" -le 5 ]; then
        echo "- **Status**: ✅ COMPLETED" >> "$report_file"
        echo "- **Analysis**: Firebase complexity reduced to $firebase_complexity references" >> "$report_file"
    else
        echo "- **Status**: 🔴 NOT STARTED" >> "$report_file"
        echo "- **Analysis**: Firebase still has $firebase_complexity references (target: ≤5)" >> "$report_file"
    fi
    echo "" >> "$report_file"
    
    echo "### Provider Memory Leaks (opt-003)" >> "$report_file"
    if grep -q "dispose()" "$PROJECT_ROOT/lib/providers/"*.dart 2>/dev/null; then
        echo "- **Status**: 🟡 IN PROGRESS" >> "$report_file"
        echo "- **Analysis**: dispose() methods found in providers" >> "$report_file"
    else
        echo "- **Status**: 🔴 NOT STARTED" >> "$report_file"
        echo "- **Analysis**: No dispose() methods found in providers" >> "$report_file"
    fi
    echo "" >> "$report_file"
    
    # Add performance metrics section
    cat >> "$report_file" << EOF

## 📈 Performance Metrics

### Code Quality
- **Flutter Analyze**: $(flutter analyze --no-congratulate 2>&1 | grep -c "issues found" || echo "0") issues found
- **Test Coverage**: Not measured
- **Performance Tests**: $([ -f "test/performance/optimization_tests.dart" ] && echo "Available" || echo "Not Found")

### Build Status
- **Last Build**: $([ -f "build/app/outputs/flutter-apk/app-release.apk" ] && echo "$(date -r build/app/outputs/flutter-apk/app-release.apk '+%Y-%m-%d %H:%M')" || echo "No release build found")
- **Build Size**: $([ -f "build/app/outputs/flutter-apk/app-release.apk" ] && du -h build/app/outputs/flutter-apk/app-release.apk | cut -f1 || echo "Unknown")

## 🎯 Next Actions

### Immediate (Next 24h)
$([ "$progress" -eq 0 ] && echo "- [ ] Start Sprint 1: Critical Performance Issues" || echo "- [x] Sprint 1 in progress")
$([ "$completed" -lt 3 ] && echo "- [ ] Assign critical tasks to team members" || echo "- [x] Critical tasks assigned")
- [ ] Set up baseline performance measurements
- [ ] Begin daily progress tracking

### This Week
$([ "$progress" -lt 25 ] && echo "- [ ] Complete message sorting optimization" || echo "- [x] Message sorting optimization progress")
$([ "$progress" -lt 25 ] && echo "- [ ] Simplify Firebase initialization" || echo "- [x] Firebase initialization progress")
$([ "$progress" -lt 25 ] && echo "- [ ] Implement provider disposal" || echo "- [x] Provider disposal progress")

### This Month
- [ ] Complete all 14 optimization tasks
- [ ] Validate performance improvements
- [ ] Document optimization results
- [ ] Plan maintenance and monitoring

---

*This report is automatically generated. For detailed task tracking, see OPTIMIZATION_DASHBOARD.md*
EOF

    echo "✅ Status report generated: $report_file"
}

# Function to commit changes if requested
commit_changes() {
    if [ "${1:-}" == "--commit" ]; then
        echo -e "${YELLOW}📝 Committing dashboard updates...${NC}"
        
        cd "$PROJECT_ROOT"
        
        if git status --porcelain | grep -q "OPTIMIZATION_"; then
            git add OPTIMIZATION_*.md
            git commit -m "Update optimization dashboard - $(get_timestamp)

- Updated progress metrics and task statuses
- Generated automated status report
- Analyzed code for completion indicators

🤖 Generated by update_optimization_dashboard.sh"
            
            echo "✅ Changes committed to git"
        else
            echo "ℹ️  No changes to commit"
        fi
    fi
}

# Main execution
main() {
    echo "Starting dashboard update process..."
    echo "Project root: $PROJECT_ROOT"
    echo ""
    
    # Run analysis and updates
    analyze_task_completion
    echo ""
    
    update_dashboard_metrics
    echo ""
    
    measure_performance
    echo ""
    
    update_task_statuses
    echo ""
    
    generate_status_report
    echo ""
    
    # Commit changes if requested
    commit_changes "$1"
    echo ""
    
    echo -e "${GREEN}🎉 Dashboard update completed${NC}"
    echo -e "${BLUE}📋 Check OPTIMIZATION_STATUS_REPORT.md for latest status${NC}"
    echo -e "${BLUE}📊 View OPTIMIZATION_DASHBOARD.md for full dashboard${NC}"
}

# Clean up temporary files on exit
cleanup() {
    rm -f /tmp/optimization_progress.txt /tmp/completed_tasks.txt /tmp/performance_results.json
}
trap cleanup EXIT

# Run main function with all arguments
main "$@"