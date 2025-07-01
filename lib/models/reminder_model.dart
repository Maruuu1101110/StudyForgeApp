class Reminder {
  final String id;
  final String title;
  final String? tags;
  final String description;
  final DateTime createdAt;
  final DateTime dueDate;
  final bool isPinned;
  final bool isCompleted;
  final int notificationId;
  final bool isNotifEnabled;

  Reminder({
    required this.id,
    required this.title,
    this.tags,
    required this.description,
    required this.createdAt,
    required this.dueDate,
    this.isPinned = false,
    this.isCompleted = false,
    this.notificationId = 0,
    this.isNotifEnabled = true,
  });

  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'] as String,
      title: map['title'] as String,
      tags: map['tags'] as String?,
      description: map['description'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      dueDate: DateTime.fromMillisecondsSinceEpoch(map['dueDate'] as int),
      isPinned: (map['isPinned'] is int)
          ? (map['isPinned'] == 1)
          : (map['isPinned'] as bool? ?? false),
      isCompleted: (map['isCompleted'] is int)
          ? (map['isCompleted'] == 1)
          : (map['isCompleted'] as bool? ?? false),
      notificationId: map['notificationId'] as int? ?? 0,
      isNotifEnabled: (map['isNotifEnabled'] is int)
          ? (map['isNotifEnabled'] == 1)
          : (map['isNotifEnabled'] as bool? ?? true),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'tags': tags,
      'description': description,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'dueDate': dueDate.millisecondsSinceEpoch,
      'isPinned': isPinned ? 1 : 0,
      'isCompleted': isCompleted ? 1 : 0,
      'notificationId': notificationId,
      'isNotifEnabled': isNotifEnabled ? 1 : 0,
    };
  }

  Reminder copyWith({
    String? id,
    String? title,
    String? tags,
    String? description,
    DateTime? createdAt,
    DateTime? dueDate,
    bool? isPinned,
    bool? isCompleted,
    int? notificationId,
    bool? isNotifEnabled,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      tags: tags ?? this.tags,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      isPinned: isPinned ?? this.isPinned,
      isCompleted: isCompleted ?? this.isCompleted,
      notificationId: notificationId ?? this.notificationId,
      isNotifEnabled: isNotifEnabled ?? this.isNotifEnabled,
    );
  }
}
