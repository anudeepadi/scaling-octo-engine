import 'package:flutter/material.dart';
import '../utils/performance_monitor.dart';

/// Debug dashboard for tracking optimization implementation progress
class OptimizationDashboard extends StatefulWidget {
  const OptimizationDashboard({super.key});

  @override
  State<OptimizationDashboard> createState() => _OptimizationDashboardState();
}

class _OptimizationDashboardState extends State<OptimizationDashboard> {
  final PerformanceMonitor _monitor = PerformanceMonitor();
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange, width: 2),
      ),
      child: Column(
        children: [
          _buildHeader(),
          if (_isExpanded) ...[
            _buildPerformanceMetrics(),
            _buildOptimizationStatus(),
            _buildActions(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade600, Colors.orange.shade800],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
        ),
        child: Row(
          children: [
            const Icon(Icons.speed, color: Colors.white),
            const SizedBox(width: 8),
            const Text(
              'Optimization Dashboard',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceMetrics() {
    final metrics = _monitor.getOptimizationMetrics();
    
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 Performance Metrics',
            style: TextStyle(
              color: Colors.orange,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildMetricRow('Message Sort Avg', '${metrics['message_sort_avg']?.toStringAsFixed(1) ?? 'N/A'}ms'),
          _buildMetricRow('Firebase Init', '${metrics['firebase_init_time'] ?? 'N/A'}ms'),
          _buildMetricRow('Provider Notify Avg', '${metrics['provider_notify_avg']?.toStringAsFixed(1) ?? 'N/A'}ms'),
          _buildMetricRow('Total Sorts', '${metrics['total_message_sorts'] ?? 0}'),
          _buildMetricRow('Provider Updates', '${metrics['total_provider_notifications'] ?? 0}'),
          _buildMetricRow('Firebase Ops', '${metrics['firebase_operations'] ?? 0}'),
          _buildMetricRow('Firebase Errors', '${metrics['firebase_errors'] ?? 0}'),
        ],
      ),
    );
  }

  Widget _buildOptimizationStatus() {
    final targets = _monitor.checkOptimizationTargets();
    
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🎯 Optimization Status',
            style: TextStyle(
              color: Colors.orange,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildStatusRow('Message Sort (<10ms)', targets['message_sort_optimized'] ?? false),
          _buildStatusRow('Firebase Init (<3s)', targets['firebase_init_optimized'] ?? false),
          _buildStatusRow('Provider Performance', targets['provider_performance_good'] ?? false),
          _buildStatusRow('Firebase Reliability', targets['firebase_reliability_good'] ?? false),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🔧 Actions',
            style: TextStyle(
              color: Colors.orange,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    _monitor.clearMetrics();
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Metrics cleared')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Clear Metrics'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    _monitor.logStatus();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Status logged to console')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Log Status'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showDetailedReport(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Show Detailed Report'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, bool isOptimized) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isOptimized ? Icons.check_circle : Icons.error,
            color: isOptimized ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          Text(
            isOptimized ? 'OPTIMIZED' : 'NEEDS WORK',
            style: TextStyle(
              color: isOptimized ? Colors.green : Colors.red,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailedReport() {
    final report = _monitor.generateReport();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: const Text(
          'Performance Report',
          style: TextStyle(color: Colors.orange),
        ),
        content: SingleChildScrollView(
          child: Text(
            report,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'monospace',
              fontSize: 12,
            ),
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
}

/// Widget to show optimization progress in main app
class OptimizationProgressBanner extends StatelessWidget {
  const OptimizationProgressBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final monitor = PerformanceMonitor();
    final targets = monitor.checkOptimizationTargets();
    
    final optimizedCount = targets.values.where((v) => v).length;
    final totalCount = targets.length;
    final progressPercent = totalCount > 0 ? (optimizedCount / totalCount) : 0.0;
    
    if (progressPercent >= 1.0) {
      // All optimizations complete
      return Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade700),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'All optimizations completed! 🎉',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    if (progressPercent == 0.0) {
      // No optimizations started
      return Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange),
        ),
        child: Row(
          children: [
            Icon(Icons.schedule, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Optimization implementation pending',
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    // Partial progress
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Optimization in progress: $optimizedCount/$totalCount',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progressPercent,
            backgroundColor: Colors.blue.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
          ),
        ],
      ),
    );
  }
}