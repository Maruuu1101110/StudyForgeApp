class Note {
  final String title;
  final String content;

  Note({required this.title, required this.content});
}

class NoteManager {
  final List<Note> _notes = [
    Note(
      title: "Note 1",
      content:
          "“I'm unpredictable, I never know where I'm going until I get there, I'm so random, I'm always growing, learning, changing, I'm never the same person twice. But one thing you can be sure of about me; is I will always do exactly what I want to do.” ",
    ),
    Note(
      title: "Random Notes",
      content:
          "“I'm unpredictable, I never know where I'm going until I get there, I'm so random, I'm always growing, learning, changing, I'm never the same person twice. But one thing you can be sure of about me; is I will always do exactly what I want to do.” “I'm unpredictable, I never know where I'm going until I get there, I'm so random, I'm always growing, learning, changing, I'm never the same person twice. But one thing you can be sure of about me; is I will always do exactly what I want to do.” “I'm unpredictable, I never know where I'm going until I get there, I'm so random, I'm always growing, learning, changing, I'm never the same person twice. But one thing you can be sure of about me; is I will always do exactly what I want to do.” “I'm unpredictable, I never know where I'm going until I get there, I'm so random, I'm always growing, learning, changing, I'm never the same person twice. But one thing you can be sure of about me; is I will always do exactly what I want to do.” “I'm unpredictable, I never know where I'm going until I get there, I'm so random, I'm always growing, learning, changing, I'm never the same person twice. But one thing you can be sure of about me; is I will always do exactly what I want to do.” ",
    ),
    Note(title: "Random Notes 1", content: "Buy groceries and study notes"),
  ];

  void addNote(Note note) {
    _notes.add(note);
  }

  List<Note> get allNotes => List.unmodifiable(_notes);

  List<Note> searchNotes(String query) {
    query = query.toLowerCase();
    return _notes.where((note) {
      return note.title.toLowerCase().contains(query) ||
          note.content.toLowerCase().contains(query);
    }).toList();
  }

  void printNotes() {
    for (var note in _notes) {
      print("${note.title}:\n\t${note.content}");
    }
  }
}

void main() {
  NoteManager n1 = NoteManager();
  var results = n1.searchNotes("this is");
  for (var result in results) {
    print("${result.title}:\n-${result.content}");
  }
}
