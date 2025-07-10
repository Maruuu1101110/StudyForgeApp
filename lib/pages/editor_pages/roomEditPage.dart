import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import 'package:study_forge/models/room_model.dart';
import 'package:study_forge/tables/room_table.dart';

class RoomEditPage extends StatefulWidget {
  final RoomTableManager roomTableManager;
  final Room? existingRoom;
  final String? roomID;
  final String? roomSubject;
  final String? roomSubtitle;
  final String? roomStatus;

  const RoomEditPage({
    super.key,
    required this.roomTableManager,
    this.existingRoom,
    this.roomID,
    this.roomSubject,
    this.roomSubtitle,
    this.roomStatus,
  });

  @override
  State<RoomEditPage> createState() => _RoomEditPageState();
}

class _RoomEditPageState extends State<RoomEditPage> {
  final _roomSubjectController = TextEditingController();
  final _roomSubtitleController = TextEditingController();

  late String onEditStatus = '';

  final ImagePicker _imagePicker = ImagePicker();
  XFile? _selectedImage;
  String? _selectedColor;
  late bool _isSaveEnabled = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingRoom != null) {
      _roomSubjectController.text = widget.existingRoom!.subject;
      _roomSubtitleController.text = widget.existingRoom!.subtitle ?? '';
      onEditStatus = widget.existingRoom!.status;
      _selectedColor = widget.existingRoom!.color;
    } else {
      if (widget.roomSubject != null) {
        _roomSubjectController.text = widget.roomSubject!;
      }
      if (widget.roomSubtitle != null) {
        _roomSubtitleController.text = widget.roomSubtitle!;
      }
      if (widget.roomStatus != null) {
        onEditStatus = widget.roomStatus!;
      }
    }
  }

  @override
  void dispose() {
    _roomSubjectController.dispose();
    _roomSubtitleController.dispose();
    super.dispose();
  }

  void _updateSaveButton() {
    final hasText =
        _roomSubjectController.text.trim().isNotEmpty ||
        _roomSubtitleController.text.trim().isNotEmpty;
    if (hasText != _isSaveEnabled) {
      setState(() => _isSaveEnabled = hasText);
    }
  }

  Future<void> _saveRoom() async {
    if (_roomSubjectController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subject name is required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final finalStatus = onEditStatus.isEmpty
          ? (widget.roomStatus ?? 'Active')
          : onEditStatus;

      if (widget.existingRoom == null) {
        final newRoom = Room(
          subject: _roomSubjectController.text.trim(),
          subtitle: _roomSubtitleController.text.trim().isNotEmpty
              ? _roomSubtitleController.text.trim()
              : null,
          status: finalStatus,
          imagePath: _selectedImage?.path,
          color: _selectedColor ?? '#FFC107',
          createdAt: DateTime.now(),
          lastAccessedAt: DateTime.now(),
        );

        await RoomTableManager.insertRoom(newRoom);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Room created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final updatedRoom = widget.existingRoom!.copyWith(
          subject: _roomSubjectController.text.trim(),
          subtitle: _roomSubtitleController.text.trim().isNotEmpty
              ? _roomSubtitleController.text.trim()
              : null,
          status: finalStatus,
          imagePath: _selectedImage?.path ?? widget.existingRoom!.imagePath,
          color: _selectedColor ?? widget.existingRoom!.color,
          lastAccessedAt: DateTime.now(),
        );

        await RoomTableManager.updateRoom(updatedRoom);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Room updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving room: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildColorChip(Color color, String colorHex) {
    final bool isSelected = _selectedColor == colorHex;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedColor = colorHex;
          _updateSaveButton();
        });
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.amber : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isSelected
            ? const Icon(Icons.check, color: Colors.white, size: 20)
            : null,
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: _inputDecoration(label),
      onChanged: (value) => setState(() {
        controller.text = value;
      }),
    );
  }

  // MAIN
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: Text(widget.existingRoom == null ? 'Create Room' : 'Edit Room'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),

        actions: [
          IconButton(
            icon: Icon(
              Icons.save,
              color: _isSaveEnabled ? Colors.amber : Colors.amber,
            ),
            onPressed: _saveRoom,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildTextField(_roomSubjectController, "Subject Name"),
              const SizedBox(height: 10),
              _buildTextField(_roomSubtitleController, "Subtitle (Optional)"),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.bar_chart, color: Colors.amber),
                  Text(
                    "Set Room Status: ",
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: "Petrona",
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 0,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(
                        color: const Color.fromARGB(80, 255, 193, 7),
                      ),
                    ),
                    child: DropdownButton<String>(
                      value: onEditStatus.isEmpty
                          ? widget.roomStatus ?? 'Active'
                          : onEditStatus,
                      dropdownColor: const Color.fromARGB(110, 30, 30, 30),
                      iconEnabledColor: Colors.amber,
                      underline: Container(),

                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: "Petrona",
                        fontSize: 16,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'Active',
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.play_circle,
                                color: Colors.green,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Active',
                                style: TextStyle(fontFamily: "Petrona"),
                              ),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Halt',
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.pause_circle,
                                color: Colors.orange,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Halt',
                                style: TextStyle(fontFamily: "Petrona"),
                              ),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Completed',
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.blue,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Completed',
                                style: TextStyle(fontFamily: "Petrona"),
                              ),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          onEditStatus = value!;
                          _updateSaveButton();
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.color_lens_outlined, color: Colors.amber),
                      Text(
                        "Room Color:",
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: "Petrona",
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 50,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildColorChip(Colors.amber, "#FFC107"),
                        const SizedBox(width: 8),
                        _buildColorChip(Colors.blue, "#2196F3"),
                        const SizedBox(width: 8),
                        _buildColorChip(Colors.green, "#4CAF50"),
                        const SizedBox(width: 8),
                        _buildColorChip(Colors.purple, "#9C27B0"),
                        const SizedBox(width: 8),
                        _buildColorChip(Colors.red, "#F44336"),
                        const SizedBox(width: 8),
                        _buildColorChip(Colors.orange, "#FF9800"),
                        const SizedBox(width: 8),
                        _buildColorChip(Colors.teal, "#009688"),
                        const SizedBox(width: 8),
                        _buildColorChip(Colors.pink, "#E91E63"),
                        const SizedBox(width: 8),
                        _buildColorChip(Colors.indigo, "#3F51B5"),
                        const SizedBox(width: 8),

                        GestureDetector(
                          onTap: () => _showColorPalette(),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color.fromARGB(80, 255, 193, 7),
                                width: 2,
                              ),
                              gradient: const LinearGradient(
                                colors: [
                                  Colors.red,
                                  Colors.orange,
                                  Colors.yellow,
                                  Colors.green,
                                  Colors.blue,
                                  Colors.purple,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Icon(
                              Icons.palette,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(
                    color: const Color.fromARGB(80, 255, 193, 7),
                  ),
                ),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final pickedFile = await _imagePicker.pickImage(
                      source: ImageSource.gallery,
                    );
                    if (pickedFile != null) {
                      setState(() {
                        _selectedImage = pickedFile;
                        _updateSaveButton();
                      });
                    }
                  },
                  icon: const Icon(Icons.image, color: Colors.amber),
                  label: Text(
                    _selectedImage?.name ?? "Select Room Image",
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: "Petrona",
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showColorPalette() {
    Color currentColor = _selectedColor != null
        ? Color(int.parse(_selectedColor!.substring(1), radix: 16) + 0xFF000000)
        : Colors.amber;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color.fromRGBO(30, 30, 30, 1),
          title: const Text(
            'Pick a Custom Color',
            style: TextStyle(color: Colors.white, fontFamily: "Petrona"),
          ),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: currentColor,
              onColorChanged: (Color color) {
                currentColor = color;
              },
              labelTypes: const [],
              pickerAreaBorderRadius: BorderRadius.circular(10),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
              ),
              child: const Text('Select'),
              onPressed: () {
                setState(() {
                  _selectedColor =
                      '#${currentColor.value.toRadixString(16).substring(2).toUpperCase()}';
                  _updateSaveButton();
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color.fromARGB(138, 255, 255, 255)),
      floatingLabelStyle: const TextStyle(color: Colors.amber),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.0)),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.amber, width: 2.0),
        borderRadius: BorderRadius.all(Radius.circular(16.0)),
      ),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Color.fromARGB(80, 255, 193, 7)),
        borderRadius: BorderRadius.all(Radius.circular(16.0)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
    );
  }
}
