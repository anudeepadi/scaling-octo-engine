import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class UserProfileService {
  final FirebaseFirestore _firestore;
  static const String _collection = 'user_profiles';

  UserProfileService({FirebaseFirestore? firestore}) 
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(userId).get();
      
      if (doc.exists && doc.data() != null) {
        return UserProfile.fromJson(doc.data()!);
      }
      
      return null;
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(profile.id)
          .set(profile.toJson(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save user profile: $e');
    }
  }

  Future<void> deleteUserProfile(String userId) async {
    try {
      await _firestore.collection(_collection).doc(userId).delete();
    } catch (e) {
      throw Exception('Failed to delete user profile: $e');
    }
  }

  Stream<UserProfile?> watchUserProfile(String userId) {
    return _firestore
        .collection(_collection)
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserProfile.fromJson(doc.data()!);
      }
      return null;
    });
  }

  Future<List<UserProfile>> getActiveUsers() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .where('hasOptedOut', isEqualTo: false)
          .get();

      return querySnapshot.docs
          .map((doc) => UserProfile.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get active users: $e');
    }
  }

  Future<List<UserProfile>> getUsersWithQuitDateInRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('quitDate', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('quitDate', isLessThanOrEqualTo: endDate.toIso8601String())
          .where('isActive', isEqualTo: true)
          .get();

      return querySnapshot.docs
          .map((doc) => UserProfile.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get users with quit date in range: $e');
    }
  }

  Future<void> updateProgress(String userId, {
    required int daysSmokeFree,
    required double moneySaved,
    required int cigarettesAvoided,
    List<String>? newAchievements,
  }) async {
    try {
      final updateData = {
        'daysSmokeFree': daysSmokeFree,
        'moneySaved': moneySaved,
        'cigarettesAvoided': cigarettesAvoided,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (newAchievements != null) {
        updateData['achievementsUnlocked'] = newAchievements;
      }

      await _firestore
          .collection(_collection)
          .doc(userId)
          .update(updateData);
    } catch (e) {
      throw Exception('Failed to update progress: $e');
    }
  }

  Future<Map<String, dynamic>> getStudyStatistics() async {
    try {
      final allUsers = await _firestore.collection(_collection).get();
      
      int totalUsers = 0;
      int activeUsers = 0;
      int completedOnboarding = 0;
      int completedIntake = 0;
      int optedOut = 0;
      int smokeFreeUsers = 0;
      double totalMoneySaved = 0;
      int totalCigarettesAvoided = 0;

      for (final doc in allUsers.docs) {
        final data = doc.data();
        totalUsers++;
        
        if (data['isActive'] == true) activeUsers++;
        if (data['hasCompletedOnboarding'] == true) completedOnboarding++;
        if (data['hasOptedOut'] == true) optedOut++;
        
        // Check if user has completed intake
        if (data['averageCigarettesPerDay'] != null &&
            data['nicotineDependence'] != null &&
            data['quitDate'] != null) {
          completedIntake++;
        }
        
        if (data['daysSmokeFree'] != null && data['daysSmokeFree'] > 0) {
          smokeFreeUsers++;
        }
        
        if (data['moneySaved'] != null) {
          totalMoneySaved += (data['moneySaved'] as num).toDouble();
        }
        
        if (data['cigarettesAvoided'] != null) {
          totalCigarettesAvoided += data['cigarettesAvoided'] as int;
        }
      }

      return {
        'totalUsers': totalUsers,
        'activeUsers': activeUsers,
        'completedOnboarding': completedOnboarding,
        'completedIntake': completedIntake,
        'optedOut': optedOut,
        'smokeFreeUsers': smokeFreeUsers,
        'totalMoneySaved': totalMoneySaved,
        'totalCigarettesAvoided': totalCigarettesAvoided,
        'onboardingCompletionRate': totalUsers > 0 ? completedOnboarding / totalUsers : 0,
        'intakeCompletionRate': completedOnboarding > 0 ? completedIntake / completedOnboarding : 0,
        'optOutRate': totalUsers > 0 ? optedOut / totalUsers : 0,
      };
    } catch (e) {
      throw Exception('Failed to get study statistics: $e');
    }
  }
} 