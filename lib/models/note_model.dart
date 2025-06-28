class Note {
  final String id;
  final String title;
  final String content;
  final DateTime? createdAt;
  bool isBookmarked;
  bool isMarkDown;

  Note({
    required this.id,
    required this.title,
    required this.content,
    this.createdAt,
    this.isBookmarked = false,
    this.isMarkDown = false,
  });

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      createdAt: map['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['created_at'])
          : null,
      isBookmarked: (map['bookmarked'] ?? 0) == 1,
      isMarkDown: (map['isMarkDown'] ?? 0) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'created_at': createdAt?.millisecondsSinceEpoch,
      'bookmarked': isBookmarked ? 1 : 0,
      'isMarkDown': isMarkDown ? 1 : 0,
    };
  }
}
