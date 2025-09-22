import 'package:flutter/material.dart';
import '../utils/optimization_tracker.dart';
import '../utils/performance_monitor.dart';

/// Interactive optimization dashboard widget for project management
class OptimizationDashboardWidget extends StatefulWidget {
  const OptimizationDashboardWidget({super.key});

  @override
  State<OptimizationDashboardWidget> createState() => _OptimizationDashboardWidgetState();
}

class _OptimizationDashboardWidgetState extends State<OptimizationDashboardWidget> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final OptimizationTracker _tracker = OptimizationTracker();
  final PerformanceMonitor _monitor = PerformanceMonitor();
  
  Map<String, dynamic> _stats = {};
  Map<int, Map<String, dynamic>> _sprintProgress = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await _tracker.initialize();
    setState(() {
      _stats = _tracker.getProgressStats();
      _sprintProgress = _tracker.getSprintProgress();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        title: const Text('Optimization Dashboard'),
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.assignment), text: 'Tasks'),
            Tab(icon: Icon(Icons.trending_up), text: 'Metrics'),
            Tab(icon: Icon(Icons.schedule), text: 'Sprints'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildTasksTab(),
          _buildMetricsTab(),
          _buildSprintsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgressSummaryCard(),
          const SizedBox(height: 16),
          _buildCriticalIssuesCard(),
          const SizedBox(height: 16),
          _buildSprintOverviewCard(),
          const SizedBox(height: 16),
          _buildQuickActionsCard(),
        ],
      ),
    );
  }

  Widget _buildTasksTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildTaskFilterButtons(),
          const SizedBox(height: 16),
          _buildTaskList(),
        ],
      ),
    );
  }

  Widget _buildMetricsTab() {
    final performanceMetrics = _monitor.getOptimizationMetrics();
    final targets = _monitor.checkOptimizationTargets();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPerformanceMetricsCard(performanceMetrics),
          const SizedBox(height: 16),
          _buildOptimizationTargetsCard(targets),
          const SizedBox(height: 16),
          _buildMetricsHistoryCard(),
        ],
      ),
    );
  }

  Widget _buildSprintsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          for (int sprint = 1; sprint <= 4; sprint++)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildSprintCard(sprint),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressSummaryCard() {
    final progress = _stats['overallProgress'] ?? 0.0;
    final criticalProgress = _stats['criticalProgress'] ?? 0.0;

    return Card(
      color: const Color(0xFF2D2D2D),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.orange.shade400),
                const SizedBox(width: 8),
                const Text(
                  'Progress Summary',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildProgressIndicator(
                    'Overall Progress',
                    progress,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildProgressIndicator(
                    'Critical Issues',
                    criticalProgress,
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn('Total Tasks', '${_stats['totalTasks']}'),
                _buildStatColumn('Completed', '${_stats['completedTasks']}'),
                _buildStatColumn('In Progress', '${_stats['inProgressTasks']}'),
                _buildStatColumn('Blocked', '${_stats['blockedTasks']}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCriticalIssuesCard() {
    final criticalTasks = _tracker.getTasksByPriority(TaskPriority.p0);

    return Card(
      color: const Color(0xFF2D2D2D),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.red.shade400),
                const SizedBox(width: 8),
                const Text(
                  'Critical Issues (P0)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (final task in criticalTasks)
              _buildTaskTile(task, isCompact: true),
          ],
        ),
      ),
    );
  }

  Widget _buildSprintOverviewCard() {
    return Card(
      color: const Color(0xFF2D2D2D),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timeline, color: Colors.green.shade400),
                const SizedBox(width: 8),
                const Text(
                  'Sprint Overview',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                for (int sprint = 1; sprint <= 4; sprint++)
                  Expanded(
                    child: _buildSprintSummary(sprint),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Card(
      color: const Color(0xFF2D2D2D),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flash_on, color: Colors.yellow.shade400),
                const SizedBox(width: 8),
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildActionButton('Export Report', Icons.file_download, _exportReport),
                _buildActionButton('Clear Metrics', Icons.clear_all, _clearMetrics),
                _buildActionButton('Refresh Data', Icons.refresh, _loadData),
                _buildActionButton('Test Performance', Icons.speed, _runPerformanceTest),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskFilterButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _filterTasks(TaskPriority.p0),
            icon: const Icon(Icons.priority_high),
            label: const Text('Critical'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _filterTasks(TaskStatus.inProgress),
            icon: const Icon(Icons.play_circle),
            label: const Text('In Progress'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _filterTasks(TaskStatus.blocked),
            icon: const Icon(Icons.block),
            label: const Text('Blocked'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade700),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskList() {
    final tasks = _tracker.tasks;
    
    return Column(
      children: tasks.map((task) => _buildTaskTile(task)).toList(),
    );
  }

  Widget _buildTaskTile(OptimizationTask task, {bool isCompact = false}) {
    return Card(
      color: const Color(0xFF3D3D3D),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: _buildPriorityIndicator(task.priority),
        title: Text(
          task.title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: isCompact 
          ? Text(task.status.label, style: const TextStyle(color: Colors.white70))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.description, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 4),
                Text('Sprint ${task.sprint} • ${task.status.label}', 
                     style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
        trailing: isCompact
          ? Icon(_getStatusIcon(task.status), color: _getStatusColor(task.status))
          : PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) => _handleTaskAction(task, value),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'start', child: Text('Start Task')),
                const PopupMenuItem(value: 'complete', child: Text('Mark Complete')),
                const PopupMenuItem(value: 'block', child: Text('Mark Blocked')),
                const PopupMenuItem(value: 'assign', child: Text('Assign')),
              ],
            ),
        onTap: () => _showTaskDetails(task),
      ),
    );
  }

  Widget _buildSprintCard(int sprint) {
    final sprintData = _sprintProgress[sprint] ?? {};
    final progress = sprintData['progress'] ?? 0.0;
    final status = sprintData['status'] ?? 'Not Started';
    final tasks = _tracker.getTasksBySprint(sprint);

    return Card(
      color: const Color(0xFF2D2D2D),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timer, color: Colors.blue.shade400),
                const SizedBox(width: 8),
                Text(
                  'Sprint $sprint',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  status,
                  style: TextStyle(
                    color: _getSprintStatusColor(status),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress / 100,
              backgroundColor: Colors.grey.shade700,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade400),
            ),
            const SizedBox(height: 8),
            Text(
              '${progress.toStringAsFixed(1)}% Complete (${sprintData['completedTasks']}/${sprintData['totalTasks']} tasks)',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            for (final task in tasks.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(_getStatusIcon(task.status), 
                         color: _getStatusColor(task.status), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        task.title,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            if (tasks.length > 3)
              Text(
                '... and ${tasks.length - 3} more tasks',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceMetricsCard(Map<String, dynamic> metrics) {
    return Card(
      color: const Color(0xFF2D2D2D),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.speed, color: Colors.purple.shade400),
                const SizedBox(width: 8),
                const Text(
                  'Performance Metrics',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (final entry in metrics.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.key.replaceAll('_', ' ').toUpperCase(),
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    Text(
                      entry.value.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptimizationTargetsCard(Map<String, bool> targets) {
    return Card(
      color: const Color(0xFF2D2D2D),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.target, color: Colors.green.shade400),
                const SizedBox(width: 8),
                const Text(
                  'Optimization Targets',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (final entry in targets.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      entry.value ? Icons.check_circle : Icons.error,
                      color: entry.value ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.key.replaceAll('_', ' ').toUpperCase(),
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    Text(
                      entry.value ? 'MET' : 'PENDING',
                      style: TextStyle(
                        color: entry.value ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsHistoryCard() {
    return Card(
      color: const Color(0xFF2D2D2D),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: Colors.cyan.shade400),
                const SizedBox(width: 8),
                const Text(
                  'Metrics History',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Metrics history chart would be implemented here\nwith historical performance data visualization',
                style: TextStyle(color: Colors.white54),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods for UI components
  Widget _buildProgressIndicator(String label, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress / 100,
          backgroundColor: Colors.grey.shade700,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
        const SizedBox(height: 4),
        Text(
          '${progress.toStringAsFixed(1)}%',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildSprintSummary(int sprint) {
    final sprintData = _sprintProgress[sprint] ?? {};
    final progress = sprintData['progress'] ?? 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Text(
            'S$sprint',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 60,
            width: 8,
            child: RotatedBox(
              quarterTurns: 3,
              child: LinearProgressIndicator(
                value: progress / 100,
                backgroundColor: Colors.grey.shade700,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade400),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${progress.toStringAsFixed(0)}%',
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildPriorityIndicator(TaskPriority priority) {
    final colors = {
      TaskPriority.p0: Colors.red,
      TaskPriority.p1: Colors.orange,
      TaskPriority.p2: Colors.yellow,
      TaskPriority.p3: Colors.green,
    };

    return Container(
      width: 4,
      height: 40,
      decoration: BoxDecoration(
        color: colors[priority],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  IconData _getStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.notStarted:
        return Icons.radio_button_unchecked;
      case TaskStatus.inProgress:
        return Icons.play_circle;
      case TaskStatus.testing:
        return Icons.science;
      case TaskStatus.completed:
        return Icons.check_circle;
      case TaskStatus.blocked:
        return Icons.block;
    }
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.notStarted:
        return Colors.grey;
      case TaskStatus.inProgress:
        return Colors.orange;
      case TaskStatus.testing:
        return Colors.blue;
      case TaskStatus.completed:
        return Colors.green;
      case TaskStatus.blocked:
        return Colors.red;
    }
  }

  Color _getSprintStatusColor(String status) {
    if (status.contains('Complete')) return Colors.green;
    if (status.contains('Progress')) return Colors.orange;
    if (status.contains('Blocked')) return Colors.red;
    return Colors.grey;
  }

  // Action handlers
  void _filterTasks(dynamic filter) {
    // Implement task filtering logic
  }

  void _handleTaskAction(OptimizationTask task, String action) {
    switch (action) {
      case 'start':
        _tracker.updateTaskStatus(task.id, TaskStatus.inProgress);
        break;
      case 'complete':
        _tracker.updateTaskStatus(task.id, TaskStatus.completed);
        break;
      case 'block':
        _tracker.updateTaskStatus(task.id, TaskStatus.blocked);
        break;
      case 'assign':
        _showAssignDialog(task);
        break;
    }
    _loadData();
  }

  void _showTaskDetails(OptimizationTask task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: Text(task.title, style: const TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Description: ${task.description}', 
                   style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Text('Priority: ${task.priority.label}', 
                   style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Text('Status: ${task.status.label}', 
                   style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Text('Location: ${task.location}', 
                   style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Text('Expected Improvement: ${task.expectedImprovement}', 
                   style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAssignDialog(OptimizationTask task) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text('Assign Task', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter assignee name',
            hintStyle: TextStyle(color: Colors.white54),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _tracker.assignTask(task.id, controller.text);
              Navigator.of(context).pop();
              _loadData();
            },
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }

  void _exportReport() {
    final report = _tracker.generateDashboardReport();
    // In a real implementation, this would save the report to a file
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report exported successfully')),
    );
  }

  void _clearMetrics() {
    _monitor.clearMetrics();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Metrics cleared')),
    );
  }

  void _runPerformanceTest() {
    // Run a quick performance test
    _monitor.startTimer('test_operation');
    Future.delayed(const Duration(milliseconds: 100), () {
      _monitor.stopTimer('test_operation');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Performance test completed')),
      );
    });
  }
}