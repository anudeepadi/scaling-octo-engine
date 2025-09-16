import 'package:flutter/material.dart';

enum QuitReadiness { yes, no, unsure }
enum NicotineDependence { low, moderate, high }
enum SupportNetworkType { family, friends, partner, coworkers, healthcare, none }

class UserProfile {
  final String id;
  final String? displayName;
  final String? email;
  final String? photoUrl;
  
  // Onboarding & Consent
  final bool hasCompletedOnboarding;
  final bool hasAcceptedTerms;
  final DateTime? consentDate;
  final String preferredLanguage; // 'en' or 'es'
  
  // Intake Questionnaire
  final int? averageCigarettesPerDay;
  final NicotineDependence? nicotineDependence;
  final List<String> reasonsForQuitting;
  final List<SupportNetworkType> supportNetwork;
  final QuitReadiness? readinessToQuit;
  final TimeOfDay? dailyChatTime;
  final DateTime? quitDate;
  
  // User Settings
  final bool notificationsEnabled;
  final TimeOfDay? notificationStartTime;
  final TimeOfDay? notificationEndTime;
  final bool highContrastMode;
  
  // Progress Tracking
  final DateTime? actualQuitDate;
  final int daysSmokeFree;
  final double moneySaved;
  final int cigarettesAvoided;
  final List<String> achievementsUnlocked;
  
  // Study Participation
  final bool isActive;
  final bool hasOptedOut;
  final DateTime? optOutDate;
  final String? optOutReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    this.displayName,
    this.email,
    this.photoUrl,
    this.hasCompletedOnboarding = false,
    this.hasAcceptedTerms = false,
    this.consentDate,
    this.preferredLanguage = 'en',
    this.averageCigarettesPerDay,
    this.nicotineDependence,
    this.reasonsForQuitting = const [],
    this.supportNetwork = const [],
    this.readinessToQuit,
    this.dailyChatTime,
    this.quitDate,
    this.notificationsEnabled = true,
    this.notificationStartTime,
    this.notificationEndTime,
    this.highContrastMode = false,
    this.actualQuitDate,
    this.daysSmokeFree = 0,
    this.moneySaved = 0.0,
    this.cigarettesAvoided = 0,
    this.achievementsUnlocked = const [],
    this.isActive = true,
    this.hasOptedOut = false,
    this.optOutDate,
    this.optOutReason,
    required this.createdAt,
    required this.updatedAt,
  });

  UserProfile copyWith({
    String? id,
    String? displayName,
    String? email,
    String? photoUrl,
    bool? hasCompletedOnboarding,
    bool? hasAcceptedTerms,
    DateTime? consentDate,
    String? preferredLanguage,
    int? averageCigarettesPerDay,
    NicotineDependence? nicotineDependence,
    List<String>? reasonsForQuitting,
    List<SupportNetworkType>? supportNetwork,
    QuitReadiness? readinessToQuit,
    TimeOfDay? dailyChatTime,
    DateTime? quitDate,
    bool? notificationsEnabled,
    TimeOfDay? notificationStartTime,
    TimeOfDay? notificationEndTime,
    bool? highContrastMode,
    DateTime? actualQuitDate,
    int? daysSmokeFree,
    double? moneySaved,
    int? cigarettesAvoided,
    List<String>? achievementsUnlocked,
    bool? isActive,
    bool? hasOptedOut,
    DateTime? optOutDate,
    String? optOutReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      hasAcceptedTerms: hasAcceptedTerms ?? this.hasAcceptedTerms,
      consentDate: consentDate ?? this.consentDate,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      averageCigarettesPerDay: averageCigarettesPerDay ?? this.averageCigarettesPerDay,
      nicotineDependence: nicotineDependence ?? this.nicotineDependence,
      reasonsForQuitting: reasonsForQuitting ?? this.reasonsForQuitting,
      supportNetwork: supportNetwork ?? this.supportNetwork,
      readinessToQuit: readinessToQuit ?? this.readinessToQuit,
      dailyChatTime: dailyChatTime ?? this.dailyChatTime,
      quitDate: quitDate ?? this.quitDate,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notificationStartTime: notificationStartTime ?? this.notificationStartTime,
      notificationEndTime: notificationEndTime ?? this.notificationEndTime,
      highContrastMode: highContrastMode ?? this.highContrastMode,
      actualQuitDate: actualQuitDate ?? this.actualQuitDate,
      daysSmokeFree: daysSmokeFree ?? this.daysSmokeFree,
      moneySaved: moneySaved ?? this.moneySaved,
      cigarettesAvoided: cigarettesAvoided ?? this.cigarettesAvoided,
      achievementsUnlocked: achievementsUnlocked ?? this.achievementsUnlocked,
      isActive: isActive ?? this.isActive,
      hasOptedOut: hasOptedOut ?? this.hasOptedOut,
      optOutDate: optOutDate ?? this.optOutDate,
      optOutReason: optOutReason ?? this.optOutReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'hasCompletedOnboarding': hasCompletedOnboarding,
      'hasAcceptedTerms': hasAcceptedTerms,
      'consentDate': consentDate?.toIso8601String(),
      'preferredLanguage': preferredLanguage,
      'averageCigarettesPerDay': averageCigarettesPerDay,
      'nicotineDependence': nicotineDependence?.name,
      'reasonsForQuitting': reasonsForQuitting,
      'supportNetwork': supportNetwork.map((e) => e.name).toList(),
      'readinessToQuit': readinessToQuit?.name,
      'dailyChatTime': dailyChatTime != null ? '${dailyChatTime!.hour}:${dailyChatTime!.minute.toString().padLeft(2, '0')}' : null,
      'quitDate': quitDate?.toIso8601String(),
      'notificationsEnabled': notificationsEnabled,
      'notificationStartTime': notificationStartTime != null ? '${notificationStartTime!.hour}:${notificationStartTime!.minute.toString().padLeft(2, '0')}' : null,
      'notificationEndTime': notificationEndTime != null ? '${notificationEndTime!.hour}:${notificationEndTime!.minute.toString().padLeft(2, '0')}' : null,
      'highContrastMode': highContrastMode,
      'actualQuitDate': actualQuitDate?.toIso8601String(),
      'daysSmokeFree': daysSmokeFree,
      'moneySaved': moneySaved,
      'cigarettesAvoided': cigarettesAvoided,
      'achievementsUnlocked': achievementsUnlocked,
      'isActive': isActive,
      'hasOptedOut': hasOptedOut,
      'optOutDate': optOutDate?.toIso8601String(),
      'optOutReason': optOutReason,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      displayName: json['displayName'] as String?,
      email: json['email'] as String?,
      photoUrl: json['photoUrl'] as String?,
      hasCompletedOnboarding: json['hasCompletedOnboarding'] as bool? ?? false,
      hasAcceptedTerms: json['hasAcceptedTerms'] as bool? ?? false,
      consentDate: json['consentDate'] != null ? DateTime.parse(json['consentDate']) : null,
      preferredLanguage: json['preferredLanguage'] as String? ?? 'en',
      averageCigarettesPerDay: json['averageCigarettesPerDay'] as int?,
      nicotineDependence: json['nicotineDependence'] != null 
          ? NicotineDependence.values.firstWhere((e) => e.name == json['nicotineDependence'])
          : null,
      reasonsForQuitting: List<String>.from(json['reasonsForQuitting'] ?? []),
      supportNetwork: (json['supportNetwork'] as List<dynamic>?)
          ?.map((e) => SupportNetworkType.values.firstWhere((type) => type.name == e))
          .toList() ?? [],
      readinessToQuit: json['readinessToQuit'] != null 
          ? QuitReadiness.values.firstWhere((e) => e.name == json['readinessToQuit'])
          : null,
      dailyChatTime: json['dailyChatTime'] != null 
          ? _parseTimeOfDay(json['dailyChatTime'])
          : null,
      quitDate: json['quitDate'] != null ? DateTime.parse(json['quitDate']) : null,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      notificationStartTime: json['notificationStartTime'] != null 
          ? _parseTimeOfDay(json['notificationStartTime'])
          : null,
      notificationEndTime: json['notificationEndTime'] != null 
          ? _parseTimeOfDay(json['notificationEndTime'])
          : null,
      highContrastMode: json['highContrastMode'] as bool? ?? false,
      actualQuitDate: json['actualQuitDate'] != null ? DateTime.parse(json['actualQuitDate']) : null,
      daysSmokeFree: json['daysSmokeFree'] as int? ?? 0,
      moneySaved: (json['moneySaved'] as num?)?.toDouble() ?? 0.0,
      cigarettesAvoided: json['cigarettesAvoided'] as int? ?? 0,
      achievementsUnlocked: List<String>.from(json['achievementsUnlocked'] ?? []),
      isActive: json['isActive'] as bool? ?? true,
      hasOptedOut: json['hasOptedOut'] as bool? ?? false,
      optOutDate: json['optOutDate'] != null ? DateTime.parse(json['optOutDate']) : null,
      optOutReason: json['optOutReason'] as String?,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  static TimeOfDay _parseTimeOfDay(String timeString) {
    // Handle both "8:30" and "830" formats
    if (timeString.contains(':')) {
      final parts = timeString.split(':');
      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    } else {
      // Handle "830" format - assume it's HHMM or HMM
      if (timeString.length == 3) {
        // Format like "830" -> hour=8, minute=30
        return TimeOfDay(
          hour: int.parse(timeString.substring(0, 1)),
          minute: int.parse(timeString.substring(1)),
        );
      } else if (timeString.length == 4) {
        // Format like "1130" -> hour=11, minute=30
        return TimeOfDay(
          hour: int.parse(timeString.substring(0, 2)),
          minute: int.parse(timeString.substring(2)),
        );
      } else {
        // Fallback: assume it's just hours
        return TimeOfDay(
          hour: int.parse(timeString),
          minute: 0,
        );
      }
    }
  }

  // Helper methods
  bool get hasCompletedIntake => 
      averageCigarettesPerDay != null &&
      nicotineDependence != null &&
      reasonsForQuitting.isNotEmpty &&
      readinessToQuit != null &&
      dailyChatTime != null &&
      quitDate != null;

  int get daysUntilQuitDate {
    if (quitDate == null) return 0;
    final now = DateTime.now();
    final difference = quitDate!.difference(DateTime(now.year, now.month, now.day));
    return difference.inDays;
  }

  bool get isInPreQuitPhase => daysUntilQuitDate > 0;
  bool get isOnQuitDay => daysUntilQuitDate == 0;
  bool get isInPostQuitPhase => daysUntilQuitDate < 0;

  double get estimatedMoneySavedPerDay {
    if (averageCigarettesPerDay == null) return 0.0;
    // Assuming $0.50 per cigarette (average cost)
    return averageCigarettesPerDay! * 0.50;
  }
} 