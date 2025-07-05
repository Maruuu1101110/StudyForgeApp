// Room model for study session rooms

class Room {
  final int? id; // Primary key, auto-increment
  final String subject; // Subject name
  final String? subtitle; // Room description/subtitle
  final String status; // Room status: "Active", "Completed", "Archived"
  final String? imagePath; // Path to subject image/icon
  final String? color; // Hex color code for the room theme
  final DateTime createdAt; // When the room was created
  final DateTime? lastAccessedAt; // When the room was last accessed
  final int totalSessions; // Total number of study sessions in this room
  final int totalStudyTime; // Total study time in minutes
  final String? goals; // JSON string of room goals/objectives
  final bool isFavorite; // Whether the room is marked as favorite
  final String? description; // Detailed room description

  Room({
    this.id,
    required this.subject,
    this.subtitle,
    this.status = "Active",
    this.imagePath,
    this.color,
    required this.createdAt,
    this.lastAccessedAt,
    this.totalSessions = 0,
    this.totalStudyTime = 0,
    this.goals,
    this.isFavorite = false,
    this.description,
  });

  // convert room to map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject': subject,
      'subtitle': subtitle,
      'status': status,
      'imagePath': imagePath,
      'color': color,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastAccessedAt': lastAccessedAt?.millisecondsSinceEpoch,
      'totalSessions': totalSessions,
      'totalStudyTime': totalStudyTime,
      'goals': goals,
      'isFavorite': isFavorite ? 1 : 0,
      'description': description,
    };
  }

  // create room from map (database query result)
  factory Room.fromMap(Map<String, dynamic> map) {
    return Room(
      id: map['id']?.toInt(),
      subject: map['subject'] ?? '',
      subtitle: map['subtitle'] ?? '',
      status: map['status'] ?? 'Active',
      imagePath: map['imagePath'],
      color: map['color'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      lastAccessedAt: map['lastAccessedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastAccessedAt'])
          : null,
      totalSessions: map['totalSessions']?.toInt() ?? 0,
      totalStudyTime: map['totalStudyTime']?.toInt() ?? 0,
      goals: map['goals'],
      isFavorite: map['isFavorite'] == 1,
      description: map['description'],
    );
  }

  // create a copy of Room with updated fields
  Room copyWith({
    int? id,
    String? subject,
    String? subtitle,
    String? status,
    String? imagePath,
    String? color,
    DateTime? createdAt,
    DateTime? lastAccessedAt,
    int? totalSessions,
    int? totalStudyTime,
    String? goals,
    bool? isFavorite,
    String? description,
  }) {
    return Room(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      subtitle: subtitle ?? this.subtitle,
      status: status ?? this.status,
      imagePath: imagePath ?? this.imagePath,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      totalSessions: totalSessions ?? this.totalSessions,
      totalStudyTime: totalStudyTime ?? this.totalStudyTime,
      goals: goals ?? this.goals,
      isFavorite: isFavorite ?? this.isFavorite,
      description: description ?? this.description,
    );
  }

  @override
  String toString() {
    return 'Room{id: $id, subject: $subject, subtitle: $subtitle, status: $status, totalSessions: $totalSessions, totalStudyTime: $totalStudyTime}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Room && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // helper methods
  String get displayStatus {
    switch (status) {
      case "Active":
        return "Ongoing";
      case "Completed":
        return "Completed";
      case "Archived":
        return "Archived";
      default:
        return status;
    }
  }

  String get formattedStudyTime {
    if (totalStudyTime == 0) return "0 min";

    final hours = totalStudyTime ~/ 60;
    final minutes = totalStudyTime % 60;

    if (hours == 0) {
      return "${minutes}m";
    } else if (minutes == 0) {
      return "${hours}h";
    } else {
      return "${hours}h ${minutes}m";
    }
  }

  bool get hasBeenAccessed => lastAccessedAt != null;

  Duration get timeSinceLastAccess {
    if (lastAccessedAt == null) return Duration.zero;
    return DateTime.now().difference(lastAccessedAt!);
  }
}
