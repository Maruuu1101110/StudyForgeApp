import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:study_forge/models/user_profile_model.dart';
import 'package:study_forge/tables/db_helper.dart';

class UserProfileManager {
  static Database? _database;
  UserProfileManager._internal();
  static final UserProfileManager _instance = UserProfileManager._internal();
  factory UserProfileManager() => _instance;

  static const String createUserProfileTableSQL = '''
    CREATE TABLE IF NOT EXISTS user_profiles(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL DEFAULT 'Study Forger',
      level INTEGER DEFAULT 1,
      experience_points INTEGER DEFAULT 0,
      study_streak INTEGER DEFAULT 0,
      last_study_date TEXT,
      total_study_sessions INTEGER DEFAULT 0,
      notes_created INTEGER DEFAULT 0,
      reminders_completed INTEGER DEFAULT 0,
      achievements_unlocked INTEGER DEFAULT 0,
      badges TEXT DEFAULT '',
      created_at TEXT,
      updated_at TEXT
    )
  ''';

  Future<Database> get database async {
    if (_database != null) return _database!;
    return await _initDatabase();
  }

  Future<Database> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'study_forge.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(createUserProfileTableSQL);
      },
    );
    return _database!;
  }

  // ensure user profile table exists
  Future<void> ensureUserProfileTableExists() async {
    final db = await DBHelper.instance.database;

    await db.execute(createUserProfileTableSQL);
  }

  // get or create user profile since theres only one
  Future<UserProfile> getUserProfile() async {
    final db = await DBHelper.instance.database;

    final maps = await db.query('user_profiles', limit: 1);

    if (maps.isNotEmpty) {
      return UserProfile.fromMap(maps.first);
    } else {
      // create default profile for new user
      final defaultProfile = UserProfile(
        id: 1,
        username: 'Study Forger',
        level: 1,
        experiencePoints: 0,
        studyStreak: 0,
        lastStudyDate: DateTime.now(),
        totalStudySessions: 0,
        notesCreated: 0,
        remindersCompleted: 0,
        achievementsUnlocked: 0,
        badges: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await createUserProfile(defaultProfile);
      return defaultProfile;
    }
  }

  // create new user profile
  Future<void> createUserProfile(UserProfile profile) async {
    final db = await DBHelper.instance.database;

    await db.insert('user_profiles', profile.toMap());
  }

  // update existing user profile
  Future<void> updateUserProfile(UserProfile profile) async {
    final db = await DBHelper.instance.database;

    await db.update(
      'user_profiles',
      profile.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [profile.id],
    );
  }

  // add xp and handle level ups
  Future<UserProfile> addExperiencePoints(int points) async {
    final profile = await getUserProfile();
    int currentXP = profile.experiencePoints + points;
    int currentLevel = profile.level;

    // check for level up using grouped requirements
    while (true) {
      final int levelGroup =
          ((currentLevel - 1) ~/ 3) + 1; // groups: 1-3=1, 4-6=2, 7-9=3 etc
      final int requiredForLevel = levelGroup * 100;

      if (currentXP >= requiredForLevel) {
        currentXP = 0; // reset xp after leveling up
        currentLevel++;
      } else {
        break;
      }
    }

    final updatedProfile = profile.copyWith(
      experiencePoints: currentXP, // only store current level progress
      level: currentLevel,
    );

    await updateUserProfile(updatedProfile);
    return updatedProfile;
  }

  Future<UserProfile> updateTotalSessions(int sessions) async {
    final profile = await getUserProfile();
    final updatedProfile = profile.copyWith(totalStudySessions: sessions);

    await updateUserProfile(updatedProfile);
    return updatedProfile;
  }

  // update study streak and last study date
  Future<UserProfile> updateStudyStreak() async {
    final profile = await getUserProfile();
    final now = DateTime.now();
    final lastStudy = profile.lastStudyDate;
    final daysDifference = now.difference(lastStudy).inDays;

    int newStreak = profile.studyStreak;

    if (daysDifference == 0) {
      // Already studied today – no change needed
      return profile;
    } else if (daysDifference == 1) {
      // Consecutive day: continue streak
      newStreak = (newStreak == 0) ? 1 : newStreak + 1;
    } else {
      // Missed at least 1 day: reset streak
      newStreak = 1;
    }

    final updatedProfile = profile.copyWith(
      studyStreak: newStreak,
      lastStudyDate: now,
    );

    await updateUserProfile(updatedProfile);
    return updatedProfile;
  }

  // bump notes created counter
  Future<UserProfile> incrementNotesCreated() async {
    final profile = await getUserProfile();
    final updatedProfile = profile.copyWith(
      notesCreated: profile.notesCreated + 1,
    );

    await updateUserProfile(updatedProfile);
    // give xp for creating a note
    return await addExperiencePoints(10);
  }

  // bump reminders completed counter
  Future<UserProfile> incrementRemindersCompleted() async {
    final profile = await getUserProfile();
    final updatedProfile = profile.copyWith(
      remindersCompleted: profile.remindersCompleted + 1,
    );

    await updateUserProfile(updatedProfile);
    // give xp for completing a reminder
    return await addExperiencePoints(15);
  }

  // give user a badge
  Future<UserProfile> awardBadge(String badge) async {
    final profile = await getUserProfile();
    if (!profile.badges.contains(badge)) {
      final newBadges = List<String>.from(profile.badges)..add(badge);
      final updatedProfile = profile.copyWith(
        badges: newBadges,
        achievementsUnlocked: profile.achievementsUnlocked + 1,
      );

      await updateUserProfile(updatedProfile);
      // give xp for earning a badge
      return await addExperiencePoints(50);
    }
    return profile;
  }

  // check and give milestone badges
  Future<UserProfile> checkMilestoneBadges() async {
    final profile = await getUserProfile();

    // streak badges for consistency freaks
    if (profile.studyStreak >= 3 &&
        !profile.badges.contains('Streak Starter')) {
      return await awardBadge('Streak Starter');
    }
    if (profile.studyStreak >= 7 && !profile.badges.contains('Week Warrior')) {
      return await awardBadge('Week Warrior');
    }
    if (profile.studyStreak >= 30 && !profile.badges.contains('Month Master')) {
      return await awardBadge('Month Master');
    }
    if (profile.studyStreak >= 100 &&
        !profile.badges.contains('Century Scholar')) {
      return await awardBadge('Century Scholar');
    }

    // note creation badges
    if (profile.notesCreated >= 10 && !profile.badges.contains('Note Taker')) {
      return await awardBadge('Note Taker');
    }
    if (profile.notesCreated >= 50 && !profile.badges.contains('Note Master')) {
      return await awardBadge('Note Master');
    }

    // reminder completion badges
    if (profile.remindersCompleted >= 25 &&
        !profile.badges.contains('Task Crusher')) {
      return await awardBadge('Task Crusher');
    }

    // level progression badges
    if (profile.level >= 5 && !profile.badges.contains('Rising Star')) {
      return await awardBadge('Rising Star');
    }
    if (profile.level >= 10 && !profile.badges.contains('Study Champion')) {
      return await awardBadge('Study Champion');
    }

    return profile;
  }

  // nuke all data for testing purposes
  Future<void> clearUserProfile() async {
    final db = await DBHelper.instance.database;

    await db.delete('user_profiles');
  }
}
