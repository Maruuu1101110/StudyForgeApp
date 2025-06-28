import 'package:flutter/material.dart';
import '../algorithms/noteSearchAlgo.dart'; // if you're doing noteManager stuff

Future<void> showNoteSearchDialog(
  BuildContext context,
  NoteManager noteManager,
) async {
  showDialog(
    context: context,
    builder: (ctx) {
      final controller = TextEditingController();
      return AlertDialog(
        backgroundColor: const Color.fromRGBO(30, 30, 30, 1),
        title: const Text(
          "Search Notes",
          style: TextStyle(color: Colors.amber),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Type a keyword...",
            hintStyle: TextStyle(color: Colors.white24),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
          ),
          onChanged: (query) {
            // Optionally live search or debounce
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              final query = controller.text.trim();
              if (query.isNotEmpty) {
                // maybe pass results back via callback or do local filtering
              }
              Navigator.of(ctx).pop();
            },
            child: const Text("Search", style: TextStyle(color: Colors.amber)),
          ),
        ],
      );
    },
  );
}
