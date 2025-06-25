import 'package:flutter_multi_select_items/flutter_multi_select_items.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MultiSelectList extends StatefulWidget {
  const MultiSelectList({super.key});

  @override
  _MultiSelectListState createState() => _MultiSelectListState();
}

class _MultiSelectListState extends State<MultiSelectList> {
  List<int> selectedItems = [];
  bool isSelectionMode = false;

  void toggleSelection(int index) {
    setState(() {
      if (selectedItems.contains(index)) {
        selectedItems.remove(index);
      } else {
        selectedItems.add(index);
      }
      isSelectionMode = selectedItems.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (context, index) {
        bool isSelected = selectedItems.contains(index);
        return GestureDetector(
          onLongPress: () => toggleSelection(index),
          onTap: () {
            if (isSelectionMode) {
              toggleSelection(index);
            } else {
              // Open the card details
            }
          },
          child: Card(
            color: isSelected ? Colors.grey[300] : Colors.white,
            child: ListTile(
              title: Text('Item $index'),
              trailing: isSelected
                  ? Icon(Icons.check_box)
                  : Icon(Icons.check_box_outline_blank),
            ),
          ),
        );
      },
    );
  }
}
