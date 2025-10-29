import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme/app_theme.dart';
import '../utils/debug_config.dart';

/// Debug panel for testing different quit days in the RCS protocol
/// Only available in debug mode
class QuitDayDebugPanel extends StatefulWidget {
  final String? userId;
  final String serverUrl;

  const QuitDayDebugPanel({
    super.key,
    required this.userId,
    required this.serverUrl,
  });

  @override
  State<QuitDayDebugPanel> createState() => _QuitDayDebugPanelState();
}

class _QuitDayDebugPanelState extends State<QuitDayDebugPanel> {
  bool _isExpanded = false;
  bool _isLoading = false;
  String _lastAction = '';

  // Quit day scenarios to test
  final List<Map<String, dynamic>> _quitDayScenarios = [
    {'label': 'Pre-Quit (Day -1)', 'day': -1, 'color': Colors.blue},
    {'label': 'Quit Day (Q1)', 'day': 1, 'color': Colors.green},
    {'label': 'Day 2 (Q2)', 'day': 2, 'color': Colors.orange},
    {'label': 'Day 3 (Q3)', 'day': 3, 'color': Colors.purple},
    {'label': 'Day 4 (Q4)', 'day': 4, 'color': Colors.teal},
    {'label': 'Day 5 (Q5)', 'day': 5, 'color': Colors.pink},
    {'label': 'Day 6 (Q6)', 'day': 6, 'color': Colors.indigo},
    {'label': 'Day 7 (Q7)', 'day': 7, 'color': Colors.amber},
    {'label': 'Week 2', 'day': 14, 'color': Colors.cyan},
    {'label': 'Week 3', 'day': 21, 'color': Colors.lime},
    {'label': 'Week 4', 'day': 28, 'color': Colors.deepOrange},
  ];

  // Time scenarios for same-day testing
  final List<Map<String, dynamic>> _timeScenarios = [
    {'label': '8 AM Morning', 'time': '08:00', 'icon': Icons.wb_sunny},
    {'label': '12 PM Noon', 'time': '12:00', 'icon': Icons.wb_sunny_outlined},
    {'label': '5 PM Evening', 'time': '17:00', 'icon': Icons.wb_twilight},
    {'label': '8 PM Check-in', 'time': '20:00', 'icon': Icons.nightlight},
  ];

  Future<void> _triggerQuitDay(int day) async {
    if (widget.userId == null) {
      _showError('User not logged in');
      return;
    }

    setState(() {
      _isLoading = true;
      _lastAction = 'Loading Q$day...';
    });

    try {
      final url = '${widget.serverUrl}/debug/trigger-day';
      DebugConfig.debugPrint('[QuitDayDebug] Triggering day $day for user ${widget.userId}');

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': widget.userId,
          'quit_day': day,
          'trigger_all_messages': true,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        setState(() {
          _lastAction = '✓ Loaded Q$day';
        });
        _showSuccess('Triggered messages for Day $day');
      } else {
        setState(() {
          _lastAction = '✗ Failed Q$day';
        });
        _showError('Server error: ${response.statusCode}');
      }
    } catch (e) {
      DebugConfig.debugPrint('[QuitDayDebug] Error: $e');
      setState(() {
        _lastAction = '✗ Error Q$day';
      });
      _showError('Failed to trigger: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _triggerTimeScenario(String time) async {
    if (widget.userId == null) {
      _showError('User not logged in');
      return;
    }

    setState(() {
      _isLoading = true;
      _lastAction = 'Loading $time...';
    });

    try {
      final url = '${widget.serverUrl}/debug/trigger-time';
      DebugConfig.debugPrint('[QuitDayDebug] Triggering time $time for user ${widget.userId}');

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': widget.userId,
          'time': time,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        setState(() {
          _lastAction = '✓ Loaded $time';
        });
        _showSuccess('Triggered messages for $time');
      } else {
        setState(() {
          _lastAction = '✗ Failed $time';
        });
        _showError('Server error: ${response.statusCode}');
      }
    } catch (e) {
      DebugConfig.debugPrint('[QuitDayDebug] Error: $e');
      setState(() {
        _lastAction = '✗ Error $time';
      });
      _showError('Failed to trigger: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearAllMessages() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Messages?'),
        content: const Text('This will clear all chat messages from Firestore. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _lastAction = 'Clearing...';
    });

    try {
      final url = '${widget.serverUrl}/debug/clear-messages';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_id': widget.userId}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        setState(() {
          _lastAction = '✓ Cleared';
        });
        _showSuccess('All messages cleared');
      } else {
        setState(() {
          _lastAction = '✗ Clear failed';
        });
        _showError('Failed to clear messages');
      }
    } catch (e) {
      setState(() {
        _lastAction = '✗ Error';
      });
      _showError('Error clearing: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Only show in debug mode
    if (kReleaseMode) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 80,
      right: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Expanded panel
          if (_isExpanded) ...[
            Container(
              width: 320,
              constraints: const BoxConstraints(maxHeight: 500),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.quitxtTeal, AppTheme.quitxtPurple],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.bug_report, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Quit Day Tester',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (_isLoading)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Status
                  if (_lastAction.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: Colors.grey[100],
                      child: Text(
                        _lastAction,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                  // Scrollable content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Quit Days
                          const Text(
                            'Quit Days',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _quitDayScenarios.map((scenario) {
                              return _buildDayButton(
                                scenario['label'] as String,
                                scenario['day'] as int,
                                scenario['color'] as Color,
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 12),

                          // Time Scenarios
                          const Text(
                            'Time of Day',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...(_timeScenarios.map((scenario) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _buildTimeButton(
                                scenario['label'] as String,
                                scenario['time'] as String,
                                scenario['icon'] as IconData,
                              ),
                            );
                          }).toList()),

                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 12),

                          // Actions
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _isLoading ? null : _clearAllMessages,
                              icon: const Icon(Icons.delete_outline, size: 18),
                              label: const Text('Clear All Messages'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Toggle button
          FloatingActionButton(
            mini: true,
            backgroundColor: _isExpanded ? Colors.red : AppTheme.quitxtTeal,
            onPressed: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Icon(
              _isExpanded ? Icons.close : Icons.bug_report,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayButton(String label, int day, Color color) {
    return ElevatedButton(
      onPressed: _isLoading ? null : () => _triggerQuitDay(day),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 2,
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildTimeButton(String label, String time, IconData icon) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : () => _triggerTimeScenario(time),
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[100],
          foregroundColor: Colors.black87,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
