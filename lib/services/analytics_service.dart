import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../utils/debug_config.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics;
  final FirebaseFirestore _firestore;
  static const String _eventsCollection = 'analytics_events';
  static const String _errorsCollection = 'error_logs';

  AnalyticsService({
    FirebaseAnalytics? analytics,
    FirebaseFirestore? firestore,
  }) : _analytics = analytics ?? FirebaseAnalytics.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  // Track user events
  Future<void> trackEvent(String name, Map<String, Object> parameters) async {
    try {
      await _analytics.logEvent(
        name: name,
        parameters: parameters,
      );

      // Store event in Firestore for analysis
      await _firestore.collection(_eventsCollection).add({
        'eventName': name,
        'parameters': parameters,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      DebugConfig.debugPrint('Error tracking event: $e');
    }
  }

  // Track screen views
  Future<void> trackScreenView(String screenName) async {
    try {
      await _analytics.logScreenView(screenName: screenName);
    } catch (e) {
      DebugConfig.debugPrint('Error tracking screen view: $e');
    }
  }

  // Track user properties
  Future<void> setUserProperty(String name, String? value) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
    } catch (e) {
      DebugConfig.debugPrint('Error setting user property: $e');
    }
  }

  // Track user ID
  Future<void> setUserId(String? userId) async {
    try {
      await _analytics.setUserId(id: userId);
    } catch (e) {
      DebugConfig.debugPrint('Error setting user ID: $e');
    }
  }

  // Study-specific tracking methods
  Future<void> trackOnboardingStep(String stepName) async {
    await trackEvent('onboarding_step', {
      'step_name': stepName,
    });
  }

  Future<void> trackIntakeProgress(int stepNumber, int totalSteps) async {
    await trackEvent('intake_progress', {
      'step_number': stepNumber,
      'total_steps': totalSteps,
    });
  }

  Future<void> trackMessageInteraction(String messageId, String interactionType) async {
    await trackEvent('message_interaction', {
      'message_id': messageId,
      'interaction_type': interactionType,
    });
  }

  Future<void> trackQuickReplyUsage(String messageId, String replyType) async {
    await trackEvent('quick_reply_used', {
      'message_id': messageId,
      'reply_type': replyType,
    });
  }

  Future<void> trackProgressMilestone(String milestoneName) async {
    await trackEvent('progress_milestone', {
      'milestone_name': milestoneName,
    });
  }

  Future<void> trackOptOut(String reason) async {
    await trackEvent('user_opt_out', {
      'reason': reason,
    });
  }

  Future<void> trackHelpRequest(String helpType) async {
    await trackEvent('help_requested', {
      'help_type': helpType,
    });
  }

  Future<void> trackNotificationInteraction(String notificationId, String action) async {
    await trackEvent('notification_interaction', {
      'notification_id': notificationId,
      'action': action,
    });
  }

  Future<void> trackLanguageChange(String newLanguage) async {
    await trackEvent('language_changed', {
      'new_language': newLanguage,
    });
  }

  Future<void> trackSlipEvent(String trigger, String response) async {
    await trackEvent('slip_event', {
      'trigger': trigger,
      'response': response,
    });
  }

  // Error logging
  Future<void> logError(String errorCode, String errorMessage, [Map<String, dynamic>? parameters]) async {
    try {
      await _analytics.logEvent(
        name: 'error_occurred',
        parameters: {
          'error_code': errorCode,
          'error_message': errorMessage,
          if (parameters != null) ...parameters,
        },
      );
    } catch (e) {
      DebugConfig.debugPrint('Error logging error: $e');
    }
  }

  // Analytics queries for study monitoring
  Future<Map<String, dynamic>> getEventCounts(DateTime startDate, DateTime endDate) async {
    try {
      final snapshot = await _firestore
          .collection(_eventsCollection)
          .where('timestamp', isGreaterThanOrEqualTo: startDate)
          .where('timestamp', isLessThanOrEqualTo: endDate)
          .get();

      final events = snapshot.docs.map((doc) => doc.data()).toList();
      final eventCounts = <String, int>{};

      for (final event in events) {
        final eventName = event['eventName'] as String? ?? 'unknown';
        eventCounts[eventName] = (eventCounts[eventName] ?? 0) + 1;
      }

      return {
        'total_events': events.length,
        'event_counts': eventCounts,
        'unique_users': snapshot.docs.map((doc) => doc.data()['parameters']?['userId'] as String? ?? '').where((id) => id.isNotEmpty).toSet().length,
      };
    } catch (e) {
      DebugConfig.debugPrint('Error getting event counts: $e');
      return {
        'total_events': 0,
        'event_counts': {},
        'unique_users': 0,
      };
    }
  }

  Future<List<Map<String, dynamic>>> getUserJourney(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_eventsCollection)
          .where('parameters.userId', isEqualTo: userId)
          .orderBy('timestamp')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'event_name': data['eventName'] as String? ?? 'unknown',
          'timestamp': (data['timestamp'] as Timestamp?)?.toDate(),
          'parameters': data['parameters'] as Map<String, dynamic>? ?? {},
        };
      }).toList();
    } catch (e) {
      DebugConfig.debugPrint('Error getting user journey: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getStudyMetrics() async {
    try {
      final snapshot = await _firestore
          .collection(_eventsCollection)
          .get();

      final events = snapshot.docs.map((doc) => doc.data()).toList();
      
      return {
        'total_participants': events.map((e) => e['parameters']?['userId'] as String? ?? '').where((id) => id.isNotEmpty).toSet().length,
        'completion_rate': _calculateCompletionRate(events),
        'average_engagement': _calculateAverageEngagement(events),
        'retention_rate': _calculateRetentionRate(events),
      };
    } catch (e) {
      DebugConfig.debugPrint('Error getting study metrics: $e');
      return {
        'total_participants': 0,
        'completion_rate': 0.0,
        'average_engagement': 0.0,
        'retention_rate': 0.0,
      };
    }
  }

  double _calculateCompletionRate(List<Map<String, dynamic>> events) {
    // Implementation depends on your study's completion criteria
    return 0.0;
  }

  double _calculateAverageEngagement(List<Map<String, dynamic>> events) {
    // Implementation depends on your engagement metrics
    return 0.0;
  }

  double _calculateRetentionRate(List<Map<String, dynamic>> events) {
    // Implementation depends on your retention criteria
    return 0.0;
  }

  // Conversion funnel analysis
  Future<Map<String, dynamic>> getConversionFunnel() async {
    try {
      final snapshot = await _firestore
          .collection(_eventsCollection)
          .get();

      final events = snapshot.docs.map((doc) => doc.data()).toList();
      
      return {
        'onboarding_started': _countEventType(events, 'onboarding_step'),
        'onboarding_completed': _countEventType(events, 'onboarding_completed'),
        'intake_started': _countEventType(events, 'intake_progress'),
        'intake_completed': _countEventType(events, 'intake_completed'),
        'quit_date_set': _countEventType(events, 'quit_date_set'),
        'quit_attempted': _countEventType(events, 'quit_attempted'),
        'quit_successful': _countEventType(events, 'quit_successful'),
      };
    } catch (e) {
      DebugConfig.debugPrint('Error getting conversion funnel: $e');
      return {
        'onboarding_started': 0,
        'onboarding_completed': 0,
        'intake_started': 0,
        'intake_completed': 0,
        'quit_date_set': 0,
        'quit_attempted': 0,
        'quit_successful': 0,
      };
    }
  }

  int _countEventType(List<Map<String, dynamic>> events, String eventName) {
    return events.where((e) => e['eventName'] == eventName).length;
  }
} 