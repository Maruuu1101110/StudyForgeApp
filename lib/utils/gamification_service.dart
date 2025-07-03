import 'package:study_forge/tables/user_profile_table.dart';
import 'package:study_forge/models/user_profile_model.dart';

class GamificationService {
  static final GamificationService _instance = GamificationService._internal();
  factory GamificationService() => _instance;
  GamificationService._internal();

  final UserProfileManager _profileManager = UserProfileManager();

  // record study session and update streak
  Future<UserProfile> recordStudySession() async {
    await _profileManager.updateStudyStreak();
    await _profileManager.addExperiencePoints(25); // base xp for studying
    return await _profileManager.checkMilestoneBadges();
  }

  // record when user creates a note
  Future<UserProfile> recordNoteCreated() async {
    await _profileManager.incrementNotesCreated();
    return await _profileManager.checkMilestoneBadges();
  }

  // record when user completes a reminder
  Future<UserProfile> recordReminderCompleted() async {
    await _profileManager.incrementRemindersCompleted();
    return await _profileManager.checkMilestoneBadges();
  }

  // get current user profile data
  Future<UserProfile> getUserProfile() async {
    return await _profileManager.getUserProfile();
  }

  // check if user just leveled up
  static bool didLevelUp(UserProfile oldProfile, UserProfile newProfile) {
    return newProfile.level > oldProfile.level;
  }

  // check if user got a new badge
  static bool didEarnBadge(UserProfile oldProfile, UserProfile newProfile) {
    return newProfile.badges.length > oldProfile.badges.length;
  }

  // get current streak status
  Future<StreakStatus> getStreakStatus() async {
    final profile = await getUserProfile();
    final now = DateTime.now();
    final daysDifference = now.difference(profile.lastStudyDate).inDays;

    if (daysDifference == 0) {
      return StreakStatus.maintainedToday;
    } else if (daysDifference == 1) {
      return StreakStatus.readyToExtend;
    } else {
      return StreakStatus.broken;
    }
  }

  String getStreakMessage(int streak) {
    if (streak == 0) {
      return "Start your journey today! 🌟";
    } else if (streak < 7) {
      return "Building momentum! Keep going! 🔥";
    } else if (streak < 30) {
      return "You're on fire! Amazing streak! 🚀";
    } else if (streak < 100) {
      return "Incredible dedication! You're unstoppable! ⭐";
    } else {
      return "LEGENDARY SCHOLAR! You're an inspiration! 👑";
    }
  }

  // get title based on user level
  String getLevelTitle(int level) {
    if (level <= 5) return "Novice Scholar";
    if (level <= 10) return "Dedicated Learner";
    if (level <= 20) return "Study Master";
    if (level <= 35) return "Knowledge Seeker";
    if (level <= 50) return "Wisdom Guardian";
    return "Legendary Sage";
  }

  // calculate days until streak gets reset
  int getDaysUntilStreakReset(DateTime lastStudyDate) {
    final now = DateTime.now();
    final daysDifference = now.difference(lastStudyDate).inDays;
    return daysDifference > 1 ? 0 : 1 - daysDifference;
  }
}

enum StreakStatus { maintainedToday, readyToExtend, broken }
