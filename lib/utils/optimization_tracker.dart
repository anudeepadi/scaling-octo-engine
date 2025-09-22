import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

/// Priority levels for optimization tasks
enum TaskPriority {
  p0('P0 - Critical', 0),
  p1('P1 - High', 1),
  p2('P2 - Medium', 2),
  p3('P3 - Low', 3);

  const TaskPriority(this.label, this.value);
  final String label;
  final int value;
}

/// Status of optimization tasks
enum TaskStatus {
  notStarted('🔴 Not Started', 0),
  inProgress('🟡 In Progress', 1),
  testing('🔵 Testing', 2),
  completed('🟢 Completed', 3),
  blocked('⚫ Blocked', -1);

  const TaskStatus(this.label, this.value);
  final String label;
  final int value;
}

/// Represents an optimization task
class OptimizationTask {
  final String id;
  final String title;
  final String description;
  final TaskPriority priority;
  final String location;
  final String currentImplementation;
  final String targetImplementation;
  final String expectedImprovement;
  final int sprint;
  
  TaskStatus status;
  String? assignedTo;
  DateTime? startDate;
  DateTime? targetDate;
  DateTime? completedDate;
  String? blockedReason;
  Map<String, dynamic> metrics;
  List<String> dependencies;

  OptimizationTask({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.location,
    required this.currentImplementation,
    required this.targetImplementation,
    required this.expectedImprovement,
    required this.sprint,
    this.status = TaskStatus.notStarted,
    this.assignedTo,
    this.startDate,
    this.targetDate,
    this.completedDate,
    this.blockedReason,
    this.metrics = const {},
    this.dependencies = const [],
  });

  /// Create task from JSON
  factory OptimizationTask.fromJson(Map<String, dynamic> json) {
    return OptimizationTask(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      priority: TaskPriority.values[json['priority']],
      location: json['location'],
      currentImplementation: json['currentImplementation'],
      targetImplementation: json['targetImplementation'],
      expectedImprovement: json['expectedImprovement'],
      sprint: json['sprint'],
      status: TaskStatus.values[json['status']],
      assignedTo: json['assignedTo'],
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      targetDate: json['targetDate'] != null ? DateTime.parse(json['targetDate']) : null,
      completedDate: json['completedDate'] != null ? DateTime.parse(json['completedDate']) : null,
      blockedReason: json['blockedReason'],
      metrics: Map<String, dynamic>.from(json['metrics'] ?? {}),
      dependencies: List<String>.from(json['dependencies'] ?? []),
    );
  }

  /// Convert task to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority.index,
      'location': location,
      'currentImplementation': currentImplementation,
      'targetImplementation': targetImplementation,
      'expectedImprovement': expectedImprovement,
      'sprint': sprint,
      'status': status.index,
      'assignedTo': assignedTo,
      'startDate': startDate?.toIso8601String(),
      'targetDate': targetDate?.toIso8601String(),
      'completedDate': completedDate?.toIso8601String(),
      'blockedReason': blockedReason,
      'metrics': metrics,
      'dependencies': dependencies,
    };
  }

  /// Check if task is blocked by dependencies
  bool isBlockedByDependencies(List<OptimizationTask> allTasks) {
    return dependencies.any((depId) {
      final dep = allTasks.firstWhere((task) => task.id == depId, orElse: () => throw Exception('Dependency not found: $depId'));
      return dep.status != TaskStatus.completed;
    });
  }

  /// Get completion percentage based on status
  double get completionPercentage {
    switch (status) {
      case TaskStatus.notStarted:
        return 0.0;
      case TaskStatus.inProgress:
        return 0.5;
      case TaskStatus.testing:
        return 0.8;
      case TaskStatus.completed:
        return 1.0;
      case TaskStatus.blocked:
        return 0.0;
    }
  }
}

/// Tracks optimization implementation progress
class OptimizationTracker {
  static final OptimizationTracker _instance = OptimizationTracker._internal();
  factory OptimizationTracker() => _instance;
  OptimizationTracker._internal();

  List<OptimizationTask> _tasks = [];
  DateTime? _lastUpdated;

  /// Initialize with predefined optimization tasks
  Future<void> initialize() async {
    await _loadFromStorage();
    if (_tasks.isEmpty) {
      _initializeDefaultTasks();
      await _saveToStorage();
    }
    developer.log('OptimizationTracker initialized with ${_tasks.length} tasks', name: 'Optimization');
  }

  /// Get all tasks
  List<OptimizationTask> get tasks => List.unmodifiable(_tasks);

  /// Get tasks by priority
  List<OptimizationTask> getTasksByPriority(TaskPriority priority) {
    return _tasks.where((task) => task.priority == priority).toList();
  }

  /// Get tasks by status
  List<OptimizationTask> getTasksByStatus(TaskStatus status) {
    return _tasks.where((task) => task.status == status).toList();
  }

  /// Get tasks by sprint
  List<OptimizationTask> getTasksBySprint(int sprint) {
    return _tasks.where((task) => task.sprint == sprint).toList();
  }

  /// Update task status
  Future<void> updateTaskStatus(String taskId, TaskStatus newStatus, {String? blockedReason}) async {
    final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex == -1) return;

    final task = _tasks[taskIndex];
    final oldStatus = task.status;
    
    task.status = newStatus;
    task.blockedReason = blockedReason;
    
    // Update timestamps
    if (newStatus == TaskStatus.inProgress && oldStatus == TaskStatus.notStarted) {
      task.startDate = DateTime.now();
    } else if (newStatus == TaskStatus.completed) {
      task.completedDate = DateTime.now();
    }

    _lastUpdated = DateTime.now();
    await _saveToStorage();
    
    developer.log('Task $taskId status updated: ${oldStatus.label} → ${newStatus.label}', name: 'Optimization');
  }

  /// Assign task to team member
  Future<void> assignTask(String taskId, String assignee) async {
    final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex == -1) return;

    _tasks[taskIndex].assignedTo = assignee;
    _lastUpdated = DateTime.now();
    await _saveToStorage();
    
    developer.log('Task $taskId assigned to $assignee', name: 'Optimization');
  }

  /// Update task metrics
  Future<void> updateTaskMetrics(String taskId, Map<String, dynamic> metrics) async {
    final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex == -1) return;

    _tasks[taskIndex].metrics.addAll(metrics);
    _lastUpdated = DateTime.now();
    await _saveToStorage();
    
    developer.log('Task $taskId metrics updated', name: 'Optimization');
  }

  /// Get overall progress statistics
  Map<String, dynamic> getProgressStats() {
    final totalTasks = _tasks.length;
    final completedTasks = _tasks.where((task) => task.status == TaskStatus.completed).length;
    final inProgressTasks = _tasks.where((task) => task.status == TaskStatus.inProgress).length;
    final blockedTasks = _tasks.where((task) => task.status == TaskStatus.blocked).length;
    
    final criticalTasks = getTasksByPriority(TaskPriority.p0);
    final completedCritical = criticalTasks.where((task) => task.status == TaskStatus.completed).length;
    
    final overallProgress = totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0.0;
    final criticalProgress = criticalTasks.isNotEmpty ? (completedCritical / criticalTasks.length) * 100 : 0.0;

    return {
      'totalTasks': totalTasks,
      'completedTasks': completedTasks,
      'inProgressTasks': inProgressTasks,
      'blockedTasks': blockedTasks,
      'overallProgress': overallProgress,
      'criticalTasks': criticalTasks.length,
      'completedCritical': completedCritical,
      'criticalProgress': criticalProgress,
      'lastUpdated': _lastUpdated?.toIso8601String(),
    };
  }

  /// Get sprint progress
  Map<int, Map<String, dynamic>> getSprintProgress() {
    final sprintMap = <int, Map<String, dynamic>>{};
    
    for (int sprint = 1; sprint <= 4; sprint++) {
      final sprintTasks = getTasksBySprint(sprint);
      final completed = sprintTasks.where((task) => task.status == TaskStatus.completed).length;
      final progress = sprintTasks.isNotEmpty ? (completed / sprintTasks.length) * 100 : 0.0;
      
      sprintMap[sprint] = {
        'totalTasks': sprintTasks.length,
        'completedTasks': completed,
        'progress': progress,
        'status': _getSprintStatus(sprintTasks),
      };
    }
    
    return sprintMap;
  }

  /// Get performance metrics summary
  Map<String, dynamic> getPerformanceMetrics() {
    final metrics = <String, dynamic>{};
    
    for (final task in _tasks) {
      if (task.metrics.isNotEmpty) {
        metrics[task.id] = task.metrics;
      }
    }
    
    return metrics;
  }

  /// Export dashboard data
  Map<String, dynamic> exportDashboardData() {
    return {
      'summary': getProgressStats(),
      'sprintProgress': getSprintProgress(),
      'tasks': _tasks.map((task) => task.toJson()).toList(),
      'performanceMetrics': getPerformanceMetrics(),
      'lastUpdated': _lastUpdated?.toIso8601String(),
    };
  }

  /// Generate markdown dashboard report
  String generateDashboardReport() {
    final stats = getProgressStats();
    final sprintProgress = getSprintProgress();
    final buffer = StringBuffer();
    
    buffer.writeln('# QuitTxt Optimization Dashboard Report');
    buffer.writeln('');
    buffer.writeln('**Generated**: ${DateTime.now().toIso8601String()}');
    buffer.writeln('**Last Updated**: ${stats['lastUpdated'] ?? 'Never'}');
    buffer.writeln('');
    
    // Overall progress
    buffer.writeln('## 📊 Overall Progress');
    buffer.writeln('');
    buffer.writeln('- **Total Tasks**: ${stats['totalTasks']}');
    buffer.writeln('- **Completed**: ${stats['completedTasks']}');
    buffer.writeln('- **In Progress**: ${stats['inProgressTasks']}');
    buffer.writeln('- **Blocked**: ${stats['blockedTasks']}');
    buffer.writeln('- **Overall Progress**: ${stats['overallProgress'].toStringAsFixed(1)}%');
    buffer.writeln('- **Critical Progress**: ${stats['criticalProgress'].toStringAsFixed(1)}%');
    buffer.writeln('');
    
    // Sprint progress
    buffer.writeln('## 🚀 Sprint Progress');
    buffer.writeln('');
    sprintProgress.forEach((sprint, data) {
      buffer.writeln('### Sprint $sprint');
      buffer.writeln('- Tasks: ${data['completedTasks']}/${data['totalTasks']}');
      buffer.writeln('- Progress: ${data['progress'].toStringAsFixed(1)}%');
      buffer.writeln('- Status: ${data['status']}');
      buffer.writeln('');
    });
    
    // Task details by priority
    buffer.writeln('## 📋 Tasks by Priority');
    buffer.writeln('');
    
    for (final priority in TaskPriority.values) {
      final priorityTasks = getTasksByPriority(priority);
      if (priorityTasks.isNotEmpty) {
        buffer.writeln('### ${priority.label}');
        buffer.writeln('');
        
        for (final task in priorityTasks) {
          buffer.writeln('- **${task.title}** - ${task.status.label}');
          if (task.assignedTo != null) {
            buffer.writeln('  - Assigned: ${task.assignedTo}');
          }
          if (task.completedDate != null) {
            buffer.writeln('  - Completed: ${task.completedDate!.toIso8601String().split('T')[0]}');
          }
          buffer.writeln('  - Location: `${task.location}`');
          buffer.writeln('');
        }
      }
    }
    
    return buffer.toString();
  }

  /// Save state to persistent storage
  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'tasks': _tasks.map((task) => task.toJson()).toList(),
        'lastUpdated': _lastUpdated?.toIso8601String(),
      };
      await prefs.setString('optimization_tracker', jsonEncode(data));
    } catch (e) {
      developer.log('Failed to save optimization tracker state: $e', name: 'Optimization');
    }
  }

  /// Load state from persistent storage
  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataString = prefs.getString('optimization_tracker');
      if (dataString != null) {
        final data = jsonDecode(dataString);
        _tasks = (data['tasks'] as List)
            .map((taskJson) => OptimizationTask.fromJson(taskJson))
            .toList();
        _lastUpdated = data['lastUpdated'] != null
            ? DateTime.parse(data['lastUpdated'])
            : null;
      }
    } catch (e) {
      developer.log('Failed to load optimization tracker state: $e', name: 'Optimization');
    }
  }

  /// Get sprint status based on task completion
  String _getSprintStatus(List<OptimizationTask> tasks) {
    if (tasks.isEmpty) return '📝 Planned';
    
    final completed = tasks.where((task) => task.status == TaskStatus.completed).length;
    final inProgress = tasks.where((task) => task.status == TaskStatus.inProgress).length;
    final blocked = tasks.where((task) => task.status == TaskStatus.blocked).length;
    
    if (completed == tasks.length) return '✅ Complete';
    if (blocked > 0) return '⚫ Blocked';
    if (inProgress > 0) return '🟡 In Progress';
    return '🔴 Not Started';
  }

  /// Initialize default optimization tasks from OPTIMIZATION_REVIEW.md
  void _initializeDefaultTasks() {
    _tasks = [
      // Critical Performance Issues (P0)
      OptimizationTask(
        id: 'opt-001',
        title: 'Message Sorting Algorithm',
        description: 'Replace O(n log n) sorting with insertion-based approach',
        priority: TaskPriority.p0,
        location: 'lib/providers/chat_provider.dart:79,96,116,260,354',
        currentImplementation: 'Full sort on every message operation',
        targetImplementation: 'Insertion-based O(n) approach',
        expectedImprovement: '60-80% chat performance boost',
        sprint: 1,
      ),
      
      OptimizationTask(
        id: 'opt-002',
        title: 'Firebase Initialization',
        description: 'Simplify Firebase initialization flow',
        priority: TaskPriority.p0,
        location: 'lib/main.dart:160-282',
        currentImplementation: 'Complex retry logic with race conditions',
        targetImplementation: 'Simplified single-path initialization',
        expectedImprovement: '40-60% startup time reduction',
        sprint: 1,
      ),
      
      OptimizationTask(
        id: 'opt-003',
        title: 'Provider Memory Leaks',
        description: 'Implement proper provider lifecycle management',
        priority: TaskPriority.p0,
        location: 'Multiple provider files',
        currentImplementation: 'Unmanaged ChangeNotifierProxyProvider instances',
        targetImplementation: 'Proper disposal and lifecycle management',
        expectedImprovement: 'Prevent memory growth over time',
        sprint: 1,
      ),
      
      // State Management Optimizations (P1)
      OptimizationTask(
        id: 'opt-004',
        title: 'Provider Over-Coupling',
        description: 'Reduce coupling between ChatProvider and DashChatProvider',
        priority: TaskPriority.p1,
        location: 'lib/providers/',
        currentImplementation: 'DashChatProvider tightly coupled to ChatProvider',
        targetImplementation: 'Dependency injection or Riverpod implementation',
        expectedImprovement: 'Better architecture and maintainability',
        sprint: 2,
        dependencies: ['opt-001', 'opt-002', 'opt-003'],
      ),
      
      OptimizationTask(
        id: 'opt-005',
        title: 'Inefficient Message Processing',
        description: 'Move link preview processing off UI thread',
        priority: TaskPriority.p1,
        location: 'lib/providers/chat_provider.dart:188-222',
        currentImplementation: 'Link preview processing blocks UI thread',
        targetImplementation: 'Compute isolate or async queuing',
        expectedImprovement: 'Improved UI responsiveness',
        sprint: 2,
      ),
      
      OptimizationTask(
        id: 'opt-006',
        title: 'Redundant State Updates',
        description: 'Batch state changes to reduce notifyListeners calls',
        priority: TaskPriority.p1,
        location: 'Multiple provider files',
        currentImplementation: 'Multiple notifyListeners() calls in single operations',
        targetImplementation: 'Batch state changes',
        expectedImprovement: 'Reduced CPU usage and better performance',
        sprint: 2,
      ),
      
      // Firebase Performance Issues (P2)
      OptimizationTask(
        id: 'opt-007',
        title: 'Unoptimized Firestore Queries',
        description: 'Implement query optimization and local caching',
        priority: TaskPriority.p2,
        location: 'lib/services/',
        currentImplementation: 'No query optimization or local caching',
        targetImplementation: 'Offline persistence and query indexing',
        expectedImprovement: 'Faster data loading and offline support',
        sprint: 3,
      ),
      
      OptimizationTask(
        id: 'opt-008',
        title: 'FCM Token Management',
        description: 'Implement efficient FCM token handling',
        priority: TaskPriority.p2,
        location: 'lib/services/firebase_messaging_service.dart',
        currentImplementation: 'Token refresh not handled efficiently',
        targetImplementation: 'Token caching and delta updates',
        expectedImprovement: 'Better push notification reliability',
        sprint: 3,
      ),
      
      // Widget Performance Issues (P2)
      OptimizationTask(
        id: 'opt-009',
        title: 'Inefficient List Rendering',
        description: 'Optimize ChatMessageWidget rebuilds',
        priority: TaskPriority.p2,
        location: 'lib/widgets/chat_message_widget.dart',
        currentImplementation: 'ChatMessageWidget rebuilds unnecessarily',
        targetImplementation: 'AutomaticKeepAliveClientMixin implementation',
        expectedImprovement: 'Smoother scrolling performance',
        sprint: 3,
      ),
      
      OptimizationTask(
        id: 'opt-010',
        title: 'Missing Widget Keys',
        description: 'Add stable keys for efficient Flutter widget diffing',
        priority: TaskPriority.p2,
        location: 'lib/widgets/',
        currentImplementation: 'List items lack stable keys',
        targetImplementation: 'ValueKey or ObjectKey implementation',
        expectedImprovement: 'Better Flutter widget tree performance',
        sprint: 3,
      ),
      
      // Platform-Specific Issues (P3)
      OptimizationTask(
        id: 'opt-011',
        title: 'iOS Performance Utils Overhead',
        description: 'Optimize iOS-specific performance code',
        priority: TaskPriority.p3,
        location: 'lib/utils/ios_performance_utils.dart',
        currentImplementation: 'May cause unnecessary delays',
        targetImplementation: 'Benchmark and optimize',
        expectedImprovement: 'Faster iOS startup',
        sprint: 4,
      ),
      
      OptimizationTask(
        id: 'opt-012',
        title: 'Dependency Conflicts',
        description: 'Update outdated packages',
        priority: TaskPriority.p3,
        location: 'pubspec.yaml',
        currentImplementation: '101 packages with newer versions',
        targetImplementation: 'All packages up to date',
        expectedImprovement: 'Security and performance improvements',
        sprint: 4,
        status: TaskStatus.completed, // Already completed
        completedDate: DateTime.now(),
      ),
      
      // Memory Management Issues (P3)
      OptimizationTask(
        id: 'opt-013',
        title: 'Image Caching Strategy',
        description: 'Configure image cache limits',
        priority: TaskPriority.p3,
        location: 'lib/services/',
        currentImplementation: 'No cache size limits or LRU eviction',
        targetImplementation: 'Configure cached_network_image with memory limits',
        expectedImprovement: 'Better memory management',
        sprint: 4,
      ),
      
      OptimizationTask(
        id: 'opt-014',
        title: 'Service Singletons',
        description: 'Implement service locator pattern',
        priority: TaskPriority.p3,
        location: 'lib/services/',
        currentImplementation: 'Multiple service instances without lifecycle management',
        targetImplementation: 'Service locator pattern with proper disposal',
        expectedImprovement: 'Better resource management',
        sprint: 4,
      ),
    ];
    
    _lastUpdated = DateTime.now();
  }
}