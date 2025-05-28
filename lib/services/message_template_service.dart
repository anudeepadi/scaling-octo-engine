import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/message_template.dart';
import '../models/user_profile.dart';
import 'analytics_service.dart';

class MessageTemplateService {
  final FirebaseFirestore _firestore;
  final AnalyticsService _analytics;
  static const String _templatesCollection = 'message_templates';
  static const String _scheduledMessagesCollection = 'scheduled_messages';

  MessageTemplateService({
    FirebaseFirestore? firestore,
    required AnalyticsService analyticsService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _analytics = analyticsService;

  // Template Management
  Future<List<MessageTemplate>> getTemplates({
    MessagePhase? phase,
    MessageTrigger? trigger,
    bool? isActive,
    String? language,
  }) async {
    try {
      Query query = _firestore.collection(_templatesCollection);

      if (phase != null) {
        query = query.where('phase', isEqualTo: phase.name);
      }

      if (trigger != null) {
        query = query.where('trigger', isEqualTo: trigger.name);
      }

      if (isActive != null) {
        query = query.where('isActive', isEqualTo: isActive);
      }

      final snapshot = await query.get();
      
      return snapshot.docs
          .map((doc) => MessageTemplate.fromJson(doc.data() as Map<String, dynamic>))
          .where((template) {
            // Filter by language if specified
            if (language != null) {
              return template.content.containsKey(language) || template.content.containsKey('en');
            }
            return true;
          })
          .toList();
    } catch (e) {
      throw Exception('Failed to get templates: $e');
    }
  }

  Future<MessageTemplate?> getTemplate(String templateId) async {
    try {
      final doc = await _firestore.collection(_templatesCollection).doc(templateId).get();
      
      if (doc.exists && doc.data() != null) {
        return MessageTemplate.fromJson(doc.data()!);
      }
      
      return null;
    } catch (e) {
      throw Exception('Failed to get template: $e');
    }
  }

  Future<void> saveTemplate(MessageTemplate template) async {
    try {
      await _firestore
          .collection(_templatesCollection)
          .doc(template.id)
          .set(template.toJson(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save template: $e');
    }
  }

  Future<void> deleteTemplate(String templateId) async {
    try {
      await _firestore.collection(_templatesCollection).doc(templateId).delete();
    } catch (e) {
      throw Exception('Failed to delete template: $e');
    }
  }

  // Message Scheduling
  Future<void> scheduleMessagesForUser(
    String userId,
    UserProfile userProfile,
  ) async {
    try {
      // Get user's current phase
      final phase = _getUserPhase(userProfile);
      
      // Get templates for this phase
      final templates = await getTemplates(
        phase: phase,
        isActive: true,
        language: userProfile.preferredLanguage,
      );
      
      // Schedule messages based on user's quit date and preferences
      for (final template in templates) {
        await _scheduleTemplateForUser(userId, userProfile, template);
      }
      
      await _analytics.trackEvent('messages_scheduled', {
        'user_id': userId,
        'phase': phase.name,
        'template_count': templates.length,
      });
    } catch (e) {
      await _analytics.logError('schedule_messages_error', e.toString(), {
        'user_id': userId,
      });
      throw Exception('Failed to schedule messages: $e');
    }
  }

  Future<void> _scheduleTemplateForUser(
    String userId,
    UserProfile userProfile,
    MessageTemplate template,
  ) async {
    try {
      DateTime scheduledTime;
      
      switch (template.trigger) {
        case MessageTrigger.scheduled:
          scheduledTime = _calculateScheduledTime(userProfile, template);
          break;
        case MessageTrigger.response:
          // Response-triggered messages are not pre-scheduled
          return;
        case MessageTrigger.missed:
          // Missed messages are scheduled when a response is missed
          return;
        case MessageTrigger.help:
          // Help messages are triggered on demand
          return;
        case MessageTrigger.stop:
          // Stop messages are triggered on demand
          return;
      }
      
      final scheduledMessage = ScheduledMessage(
        id: '',
        userId: userId,
        templateId: template.id,
        scheduledTime: scheduledTime,
        isSent: false,
        sentAt: null,
        isRead: false,
        readAt: null,
        userResponse: null,
        respondedAt: null,
        retryCount: 0,
        nextRetryAt: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await _saveScheduledMessage(scheduledMessage);
    } catch (e) {
      await _analytics.logError('schedule_template_error', e.toString(), {
        'template_id': template.id,
        'user_id': userId,
      });
      throw Exception('Failed to schedule template: $e');
    }
  }

  DateTime _calculateScheduledTime(UserProfile userProfile, MessageTemplate template) {
    final quitDate = userProfile.quitDate ?? DateTime.now();
    final targetDate = quitDate.add(Duration(days: template.dayOffset));
    
    // Get user's preferred chat time
    final chatTime = userProfile.dailyChatTime ?? const TimeOfDay(hour: 9, minute: 0);
    
    // Adjust time based on template time slot
    TimeOfDay adjustedTime;
    switch (template.timeSlot) {
      case 'morning':
        adjustedTime = TimeOfDay(hour: chatTime.hour, minute: chatTime.minute);
        break;
      case 'afternoon':
        adjustedTime = TimeOfDay(hour: chatTime.hour + 4, minute: chatTime.minute);
        break;
      case 'evening':
        adjustedTime = TimeOfDay(hour: chatTime.hour + 8, minute: chatTime.minute);
        break;
      default:
        adjustedTime = chatTime;
    }
    
    return DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      adjustedTime.hour,
      adjustedTime.minute,
    );
  }

  MessagePhase _getUserPhase(UserProfile userProfile) {
    if (userProfile.isInPreQuitPhase) {
      return MessagePhase.preQuit;
    } else if (userProfile.isOnQuitDay) {
      return MessagePhase.quitDay;
    } else if (userProfile.isInPostQuitPhase) {
      return MessagePhase.postQuit;
    }
    return MessagePhase.general;
  }

  // Scheduled Message Management
  Future<void> _saveScheduledMessage(ScheduledMessage message) async {
    try {
      final docRef = await _firestore.collection(_scheduledMessagesCollection).add(message.toJson());
      
      // Update the message with the generated ID
      await docRef.update({'id': docRef.id});
    } catch (e) {
      throw Exception('Failed to save scheduled message: $e');
    }
  }

  Future<List<ScheduledMessage>> getPendingMessages(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_scheduledMessagesCollection)
          .where('userId', isEqualTo: userId)
          .where('isSent', isEqualTo: false)
          .where('scheduledTime', isLessThanOrEqualTo: Timestamp.now())
          .orderBy('scheduledTime')
          .get();

      return snapshot.docs
          .map((doc) => ScheduledMessage.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get pending messages: $e');
    }
  }

  Future<void> markMessageAsSent(String messageId) async {
    try {
      await _firestore.collection(_scheduledMessagesCollection).doc(messageId).update({
        'isSent': true,
        'sentAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to mark message as sent: $e');
    }
  }

  Future<void> markMessageAsRead(String messageId) async {
    try {
      await _firestore.collection(_scheduledMessagesCollection).doc(messageId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to mark message as read: $e');
    }
  }

  Future<void> recordUserResponse(String messageId, String response) async {
    try {
      await _firestore.collection(_scheduledMessagesCollection).doc(messageId).update({
        'userResponse': response,
        'respondedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to record user response: $e');
    }
  }

  // Analytics and Reporting
  Future<Map<String, dynamic>> getMessageStatistics(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_scheduledMessagesCollection)
          .where('userId', isEqualTo: userId)
          .get();

      int totalMessages = 0;
      int sentMessages = 0;
      int readMessages = 0;
      int respondedMessages = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        totalMessages++;
        
        if (data['isSent'] == true) sentMessages++;
        if (data['isRead'] == true) readMessages++;
        if (data['userResponse'] != null) respondedMessages++;
      }

      return {
        'totalMessages': totalMessages,
        'sentMessages': sentMessages,
        'readMessages': readMessages,
        'respondedMessages': respondedMessages,
        'deliveryRate': totalMessages > 0 ? sentMessages / totalMessages : 0,
        'readRate': sentMessages > 0 ? readMessages / sentMessages : 0,
        'responseRate': readMessages > 0 ? respondedMessages / readMessages : 0,
      };
    } catch (e) {
      throw Exception('Failed to get message statistics: $e');
    }
  }
} 