import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/user_profile_service.dart';
import '../services/analytics_service.dart';

class UserProfileProvider with ChangeNotifier {
  final UserProfileService _userProfileService;
  final AnalyticsService _analyticsService;
  
  UserProfile? _userProfile;
  bool _isLoading = false;
  String? _error;

  UserProfileProvider({
    required UserProfileService userProfileService,
    required AnalyticsService analyticsService,
  }) : _userProfileService = userProfileService,
       _analyticsService = analyticsService;

  // Getters
  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasCompletedOnboarding => _userProfile?.hasCompletedOnboarding ?? false;
  bool get hasAcceptedTerms => _userProfile?.hasAcceptedTerms ?? false;
  bool get hasCompletedIntake => _userProfile?.hasCompletedIntake ?? false;
  bool get hasOptedOut => _userProfile?.hasOptedOut ?? false;
  String get preferredLanguage => _userProfile?.preferredLanguage ?? 'en';
  String? get displayName => _userProfile?.displayName;

  // Initialize user profile
  Future<void> initializeProfile(String userId) async {
    _setLoading(true);
    try {
      _userProfile = await _userProfileService.getUserProfile(userId);
      if (_userProfile == null) {
        // Create new profile for first-time user
        _userProfile = UserProfile(
          id: userId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _userProfileService.saveUserProfile(_userProfile!);
      }
      _analyticsService.trackEvent('profile_initialized', {
        'user_id': userId,
        'has_completed_onboarding': hasCompletedOnboarding.toString(),
        'has_completed_intake': hasCompletedIntake.toString(),
      });
      _clearError();
    } catch (e) {
      _setError('Failed to initialize profile: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Update display name from Firebase Auth
  Future<void> updateDisplayName(String? displayName) async {
    if (_userProfile == null) return;
    
    try {
      _userProfile = _userProfile!.copyWith(
        displayName: displayName,
        updatedAt: DateTime.now(),
      );
      await _userProfileService.saveUserProfile(_userProfile!);
      _analyticsService.trackEvent('display_name_updated', {
        'user_id': _userProfile!.id,
        'has_display_name': (displayName != null).toString(),
      });
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Failed to update display name: $e');
    }
  }

  // Onboarding & Consent
  Future<void> completeOnboarding() async {
    if (_userProfile == null) return;
    
    _setLoading(true);
    try {
      _userProfile = _userProfile!.copyWith(
        hasCompletedOnboarding: true,
        updatedAt: DateTime.now(),
      );
      await _userProfileService.saveUserProfile(_userProfile!);
      _analyticsService.trackEvent('onboarding_completed', {
        'user_id': _userProfile!.id,
      });
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Failed to complete onboarding: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> acceptTerms() async {
    if (_userProfile == null) return;
    
    _setLoading(true);
    try {
      _userProfile = _userProfile!.copyWith(
        hasAcceptedTerms: true,
        consentDate: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _userProfileService.saveUserProfile(_userProfile!);
      _analyticsService.trackEvent('terms_accepted', {
        'user_id': _userProfile!.id,
      });
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Failed to accept terms: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> setLanguage(String languageCode) async {
    if (_userProfile == null) return;
    
    _setLoading(true);
    try {
      _userProfile = _userProfile!.copyWith(
        preferredLanguage: languageCode,
        updatedAt: DateTime.now(),
      );
      await _userProfileService.saveUserProfile(_userProfile!);
      _analyticsService.trackEvent('language_changed', {
        'user_id': _userProfile!.id,
        'language': languageCode,
      });
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Failed to set language: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Intake Questionnaire
  Future<void> updateCigarettesPerDay(int cigarettes) async {
    if (_userProfile == null) return;
    
    _userProfile = _userProfile!.copyWith(
      averageCigarettesPerDay: cigarettes,
      updatedAt: DateTime.now(),
    );
    await _saveProfileAndNotify();
  }

  Future<void> updateNicotineDependence(NicotineDependence dependence) async {
    if (_userProfile == null) return;
    
    _userProfile = _userProfile!.copyWith(
      nicotineDependence: dependence,
      updatedAt: DateTime.now(),
    );
    await _saveProfileAndNotify();
  }

  Future<void> updateReasonsForQuitting(List<String> reasons) async {
    if (_userProfile == null) return;
    
    _userProfile = _userProfile!.copyWith(
      reasonsForQuitting: reasons,
      updatedAt: DateTime.now(),
    );
    await _saveProfileAndNotify();
  }

  Future<void> updateSupportNetwork(List<SupportNetworkType> network) async {
    if (_userProfile == null) return;
    
    _userProfile = _userProfile!.copyWith(
      supportNetwork: network,
      updatedAt: DateTime.now(),
    );
    await _saveProfileAndNotify();
  }

  Future<void> updateReadinessToQuit(QuitReadiness readiness) async {
    if (_userProfile == null) return;
    
    _userProfile = _userProfile!.copyWith(
      readinessToQuit: readiness,
      updatedAt: DateTime.now(),
    );
    await _saveProfileAndNotify();
  }

  Future<void> updateDailyChatTime(TimeOfDay time) async {
    if (_userProfile == null) return;
    
    _userProfile = _userProfile!.copyWith(
      dailyChatTime: time,
      updatedAt: DateTime.now(),
    );
    await _saveProfileAndNotify();
  }

  Future<void> updateQuitDate(DateTime date) async {
    if (_userProfile == null) return;
    
    _userProfile = _userProfile!.copyWith(
      quitDate: date,
      updatedAt: DateTime.now(),
    );
    await _saveProfileAndNotify();
    
    _analyticsService.trackEvent('quit_date_set', {
      'user_id': _userProfile!.id,
      'quit_date': date.toIso8601String(),
      'days_until_quit': _userProfile!.daysUntilQuitDate,
    });
  }

  Future<void> completeIntakeQuestionnaire() async {
    if (_userProfile == null || !_userProfile!.hasCompletedIntake) return;
    
    _setLoading(true);
    try {
      await _userProfileService.saveUserProfile(_userProfile!);
      _analyticsService.trackEvent('intake_completed', {
        'user_id': _userProfile!.id,
        'cigarettes_per_day': _userProfile!.averageCigarettesPerDay ?? 0,
        'nicotine_dependence': _userProfile!.nicotineDependence?.name ?? 'unknown',
        'readiness_to_quit': _userProfile!.readinessToQuit?.name ?? 'unknown',
        'quit_date': _userProfile!.quitDate?.toIso8601String() ?? '',
      });
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Failed to complete intake: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Settings
  Future<void> updateNotificationSettings({
    bool? enabled,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
  }) async {
    if (_userProfile == null) return;
    
    _userProfile = _userProfile!.copyWith(
      notificationsEnabled: enabled ?? _userProfile!.notificationsEnabled,
      notificationStartTime: startTime ?? _userProfile!.notificationStartTime,
      notificationEndTime: endTime ?? _userProfile!.notificationEndTime,
      updatedAt: DateTime.now(),
    );
    await _saveProfileAndNotify();
  }

  Future<void> updateAccessibilitySettings({
    bool? highContrastMode,
  }) async {
    if (_userProfile == null) return;
    
    _userProfile = _userProfile!.copyWith(
      highContrastMode: highContrastMode ?? _userProfile!.highContrastMode,
      updatedAt: DateTime.now(),
    );
    await _saveProfileAndNotify();
  }

  // Progress Tracking
  Future<void> updateActualQuitDate(DateTime date) async {
    if (_userProfile == null) return;
    
    _userProfile = _userProfile!.copyWith(
      actualQuitDate: date,
      updatedAt: DateTime.now(),
    );
    await _saveProfileAndNotify();
    
    _analyticsService.trackEvent('actual_quit_date_set', {
      'user_id': _userProfile!.id,
      'actual_quit_date': date.toIso8601String(),
    });
  }

  Future<void> updateProgress() async {
    if (_userProfile == null || _userProfile!.actualQuitDate == null) return;
    
    final now = DateTime.now();
    final quitDate = _userProfile!.actualQuitDate!;
    final daysSinceQuit = now.difference(quitDate).inDays;
    
    if (daysSinceQuit >= 0) {
      final cigarettesAvoided = daysSinceQuit * (_userProfile!.averageCigarettesPerDay ?? 0);
      final moneySaved = cigarettesAvoided * 0.50; // $0.50 per cigarette
      
      _userProfile = _userProfile!.copyWith(
        daysSmokeFree: daysSinceQuit,
        cigarettesAvoided: cigarettesAvoided,
        moneySaved: moneySaved,
        updatedAt: DateTime.now(),
      );
      
      // Check for new achievements
      await _checkAndUnlockAchievements(daysSinceQuit);
      
      await _saveProfileAndNotify();
    }
  }

  Future<void> _checkAndUnlockAchievements(int daysSmokeFree) async {
    if (_userProfile == null) return;
    
    final achievements = List<String>.from(_userProfile!.achievementsUnlocked);
    bool hasNewAchievements = false;
    
    // Define achievement milestones
    final milestones = [1, 3, 7, 14, 30, 60, 90, 180, 365];
    
    for (final milestone in milestones) {
      final achievementKey = 'smoke_free_${milestone}_days';
      if (daysSmokeFree >= milestone && !achievements.contains(achievementKey)) {
        achievements.add(achievementKey);
        hasNewAchievements = true;
        
        _analyticsService.trackEvent('achievement_unlocked', {
          'user_id': _userProfile!.id,
          'achievement': achievementKey,
          'days_smoke_free': daysSmokeFree,
        });
      }
    }
    
    if (hasNewAchievements) {
      _userProfile = _userProfile!.copyWith(
        achievementsUnlocked: achievements,
        updatedAt: DateTime.now(),
      );
    }
  }

  // Opt-out handling
  Future<void> optOut(String reason) async {
    if (_userProfile == null) return;
    
    _setLoading(true);
    try {
      _userProfile = _userProfile!.copyWith(
        hasOptedOut: true,
        optOutDate: DateTime.now(),
        optOutReason: reason,
        isActive: false,
        updatedAt: DateTime.now(),
      );
      await _userProfileService.saveUserProfile(_userProfile!);
      _analyticsService.trackEvent('user_opted_out', {
        'user_id': _userProfile!.id,
        'reason': reason,
      });
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Failed to opt out: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Helper methods
  Future<void> _saveProfileAndNotify() async {
    if (_userProfile == null) return;
    
    try {
      await _userProfileService.saveUserProfile(_userProfile!);
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Failed to save profile: $e');
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  // Validation helpers
  bool validateIntakeData() {
    if (_userProfile == null) return false;
    
    return _userProfile!.averageCigarettesPerDay != null &&
           _userProfile!.averageCigarettesPerDay! > 0 &&
           _userProfile!.nicotineDependence != null &&
           _userProfile!.reasonsForQuitting.isNotEmpty &&
           _userProfile!.readinessToQuit != null &&
           _userProfile!.dailyChatTime != null &&
           _userProfile!.quitDate != null &&
           _userProfile!.quitDate!.isAfter(DateTime.now());
  }

  String? validateQuitDate(DateTime? date) {
    if (date == null) return 'Please select a quit date';
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDate = DateTime(date.year, date.month, date.day);
    
    final daysDifference = selectedDate.difference(today).inDays;
    
    if (daysDifference < 7) {
      return 'Quit date must be at least 7 days from today';
    }
    
    if (daysDifference > 14) {
      return 'Quit date must be within 14 days from today';
    }
    
    return null;
  }

  // Refresh profile data
  Future<void> refreshProfile() async {
    if (_userProfile == null) return;
    
    _setLoading(true);
    try {
      final refreshedProfile = await _userProfileService.getUserProfile(_userProfile!.id);
      if (refreshedProfile != null) {
        _userProfile = refreshedProfile;
        _clearError();
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to refresh profile: $e');
    } finally {
      _setLoading(false);
    }
  }
} 