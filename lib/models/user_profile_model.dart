class UserProfile {
  final int id;
  final String username;
  final int level;
  final int experiencePoints;
  final int studyStreak;
  final DateTime lastStudyDate;
  final int totalStudySessions;
  final int notesCreated;
  final int remindersCompleted;
  final int achievementsUnlocked;
  final List<String> badges;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.username,
    required this.level,
    required this.experiencePoints,
    required this.studyStreak,
    required this.lastStudyDate,
    required this.totalStudySessions,
    required this.notesCreated,
    required this.remindersCompleted,
    required this.achievementsUnlocked,
    required this.badges,
    required this.createdAt,
    required this.updatedAt,
  });

  // convert from database map to object
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] ?? 0,
      username: map['username'] ?? 'Study Forger',
      level: map['level'] ?? 1,
      experiencePoints: map['experience_points'] ?? 0,
      studyStreak: map['study_streak'] ?? 0,
      lastStudyDate: DateTime.parse(
        map['last_study_date'] ?? DateTime.now().toIso8601String(),
      ),
      totalStudySessions: map['total_study_sessions'] ?? 0,
      notesCreated: map['notes_created'] ?? 0,
      remindersCompleted: map['reminders_completed'] ?? 0,
      achievementsUnlocked: map['achievements_unlocked'] ?? 0,
      badges: (map['badges'] as String? ?? '').isEmpty
          ? []
          : (map['badges'] as String)
                .split(',')
                .where((s) => s.isNotEmpty)
                .toList(),
      createdAt: DateTime.parse(
        map['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        map['updated_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  // convert object back to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'level': level,
      'experience_points': experiencePoints,
      'study_streak': studyStreak,
      'last_study_date': lastStudyDate.toIso8601String(),
      'total_study_sessions': totalStudySessions,
      'notes_created': notesCreated,
      'reminders_completed': remindersCompleted,
      'achievements_unlocked': achievementsUnlocked,
      'badges': badges.join(','),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // helper methods for gamification
  int get experienceToNextLevel {
    final int levelGroup = ((level - 1) ~/ 3) + 1;
    final int requiredForCurrentLevel = levelGroup * 100;
    return requiredForCurrentLevel - experiencePoints;
  }

  double get levelProgress {
    final int levelGroup = ((level - 1) ~/ 3) + 1; // same grouping logic
    final int requiredForCurrentLevel = levelGroup * 100;
    return experiencePoints / requiredForCurrentLevel;
  }

  // check if streak should continue or no
  bool get shouldMaintainStreak {
    final now = DateTime.now();
    final daysDifference = now.difference(lastStudyDate).inDays;
    return daysDifference <= 1; // same day or next day is fine
  }

  // copy with method for partial updates
  UserProfile copyWith({
    int? id,
    String? username,
    int? level,
    int? experiencePoints,
    int? studyStreak,
    DateTime? lastStudyDate,
    int? totalStudySessions,
    int? notesCreated,
    int? remindersCompleted,
    int? achievementsUnlocked,
    List<String>? badges,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      level: level ?? this.level,
      experiencePoints: experiencePoints ?? this.experiencePoints,
      studyStreak: studyStreak ?? this.studyStreak,
      lastStudyDate: lastStudyDate ?? this.lastStudyDate,
      totalStudySessions: totalStudySessions ?? this.totalStudySessions,
      notesCreated: notesCreated ?? this.notesCreated,
      remindersCompleted: remindersCompleted ?? this.remindersCompleted,
      achievementsUnlocked: achievementsUnlocked ?? this.achievementsUnlocked,
      badges: badges ?? this.badges,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
