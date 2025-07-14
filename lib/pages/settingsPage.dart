import 'package:flutter/material.dart';
import 'package:study_forge/components/sideBar.dart';
import 'package:study_forge/themes/forge_colors.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _appVersion = "";
  bool _limitMemoryPersistence = false;

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = 'v${info.version}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ForgeColors.scaffoldBackground,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        elevation: 0,
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              Colors.amber.shade200,
              Colors.amber,
              Colors.orange.shade300,
            ],
          ).createShader(bounds),
          child: const Text(
            "Settings",
            style: TextStyle(fontSize: 26, letterSpacing: 1.2),
          ),
        ),
        titleSpacing: 0,
        leading: Builder(
          builder: (context) {
            return Container(
              child: IconButton(
                icon: Icon(
                  Icons.menu_rounded,
                  color: ForgeColors.white,
                  size: 24,
                ),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            );
          },
        ),
      ),
      drawer: ForgeDrawer(selectedTooltip: "Settings"),
      body: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: ForgeColors.black40,
          boxShadow: [
            BoxShadow(
              color: ForgeColors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: ListView(
          children: [
            _buildSectionTitle("Memory"),
            SwitchListTile(
              title: Text("Cram Mode", style: ForgeTextStyles.tileTitle),
              subtitle: Text(
                "Temporarily expands Ember’s short-term memory from 5 to 15 sets.\n"
                "Best for long review sessions.\n"
                "⚠️ May affect performance — use only when needed.",
                style: ForgeTextStyles.tileSubtitle,
              ),
              value: _limitMemoryPersistence,
              activeColor: ForgeColors.amber300,
              onChanged: (value) {
                setState(() {
                  _limitMemoryPersistence = value;
                });

                // 🔧 Hook into Ember's memory handler here
                EmberMemoryController.instance.updateShortTermLimit(
                  value ? 15 : 5,
                );
              },
            ),

            ListTile(
              leading: Icon(Icons.memory, color: ForgeColors.amber),
              title: Text("AI Model", style: ForgeTextStyles.tileTitle),
              subtitle: Text("Ember 3.3", style: ForgeTextStyles.tileSubtitle),
              onTap: () {},
            ),
            const Divider(),
            EmberAPISettingsTile(),
            const Divider(),
            _buildSectionTitle("About"),
            ListTile(
              leading: Icon(Icons.info_outline, color: ForgeColors.amber),
              title: Text("App Version", style: ForgeTextStyles.tileTitle),
              subtitle: Text(
                _appVersion.isEmpty ? "Loading..." : _appVersion,
                style: ForgeTextStyles.tileSubtitle,
              ),
              trailing: Icon(
                Icons.copyright,
                color: ForgeColors.amber100,
                size: 18,
              ),
              onTap: () {},
            ),

            ListTile(
              leading: Icon(Icons.help_outline, color: ForgeColors.amber),
              title: Text("Help & Support", style: ForgeTextStyles.tileTitle),
              subtitle: Text(
                "FAQ, Contact, Feedback",
                style: ForgeTextStyles.tileSubtitle,
              ),
              onTap: () {
                SettingsManager().logEntireDatabase();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(title, style: ForgeTextStyles.sectionHeader),
    );
  }
}

class ForgeTextStyles {
  static final sectionHeader = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: ForgeColors.amber300,
    letterSpacing: 1.1,
  );

  static final tileTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static final tileSubtitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: Colors.white,
  );
}

class EmberMemoryController {
  static final instance = EmberMemoryController._();
  EmberMemoryController._();

  int shortTermLimit = 5;

  void updateShortTermLimit(int value) {
    shortTermLimit = value;
    debugPrint("Ember's short-term memory limit set to $value sets");
  }
}

class SettingsManager {
  static final SettingsManager _instance = SettingsManager._internal();
  factory SettingsManager() => _instance;
  SettingsManager._internal();

  static Database? _db;

  static const String createSettingsTableSQL = '''
    CREATE TABLE IF NOT EXISTS app_settings (
      key TEXT PRIMARY KEY,
      value TEXT
    );
  ''';

  Future<Database> get database async {
    if (_db != null) return _db!;
    return await _initDb();
  }

  Future<Database> _initDb() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'studyforge.db');
    final db = await openDatabase(path, version: 1);
    await db.execute(createSettingsTableSQL);
    _db = db;
    return db;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert('app_settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final result = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (result.isNotEmpty) {
      return result.first['value'] as String;
    }
    return null;
  }

  Future<void> logEntireDatabase() async {
    final db = await database;

    // Get all table names
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';",
    );

    for (final table in tables) {
      final tableName = table['name'];
      debugPrint('📁 Table: $tableName');

      final rows = await db.query(tableName.toString());
      if (rows.isEmpty) {
        debugPrint('   ↪ (empty)');
      } else {
        for (var row in rows) {
          debugPrint('   🔹 $row');
        }
      }
    }
  }

  Future<void> debugPrintAllSettings() async {
    final db = await database;
    final result = await db.query('app_settings');

    if (result.isEmpty) {
      debugPrint('⚠️ No settings found in app_settings.');
    } else {
      debugPrint('📋 Current Settings in app_settings:');
      for (final row in result) {
        debugPrint('• ${row['key']} => ${row['value']}');
      }
    }
  }
}

class EmberAPISettingsTile extends StatefulWidget {
  @override
  _EmberAPISettingsTileState createState() => _EmberAPISettingsTileState();
}

class _EmberAPISettingsTileState extends State<EmberAPISettingsTile> {
  bool _showFields = false;
  final _apiKeyController = TextEditingController();
  final _apiUrlController = TextEditingController();

  static const _apiKeyKey = 'ember_api_key';
  static const _apiUrlKey = 'ember_api_url';

  @override
  void initState() {
    super.initState();
    _loadSavedValues();
  }

  Future<void> _loadSavedValues() async {
    final apiKey = await SettingsManager().getSetting(_apiKeyKey);
    final apiUrl = await SettingsManager().getSetting(_apiUrlKey);
    setState(() {
      _apiKeyController.text = apiKey ?? '';
      _apiUrlController.text = apiUrl ?? '';
    });
  }

  void _toggleFields() {
    setState(() => _showFields = !_showFields);
  }

  Future<void> _saveSettings() async {
    final apiKey = _apiKeyController.text.trim();
    final apiUrl = _apiUrlController.text.trim();

    await SettingsManager().setSetting(_apiKeyKey, apiKey);
    await SettingsManager().setSetting(_apiUrlKey, apiUrl);

    debugPrint("✅ Saved API: $apiUrl | Key: $apiKey");

    SnackBar(content: Text("Ember’s API settings updated"));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Icon(Icons.api, color: ForgeColors.amber),
          title: Text("Ember AI API Config", style: ForgeTextStyles.tileTitle),
          subtitle: Text(
            "Tap to configure API endpoint and key.",
            style: ForgeTextStyles.tileSubtitle,
          ),
          trailing: Icon(_showFields ? Icons.expand_less : Icons.expand_more),
          onTap: _toggleFields,
        ),
        if (_showFields)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                TextField(
                  autofillHints: null,
                  enableSuggestions: false,
                  enableIMEPersonalizedLearning: false,
                  autocorrect: false,
                  controller: _apiUrlController,
                  decoration: InputDecoration(
                    floatingLabelStyle: TextStyle(color: ForgeColors.amber300),
                    labelText: "API URL",
                    hintText: "https://api.your-llm.dev",
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  autofillHints: null,
                  enableSuggestions: false,
                  enableIMEPersonalizedLearning: false,
                  autocorrect: false,
                  controller: _apiKeyController,
                  decoration: InputDecoration(
                    floatingLabelStyle: TextStyle(color: ForgeColors.amber300),
                    labelText: "API Key",
                    hintText: "sk-XXXX...",
                  ),
                  obscureText: true,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _saveSettings,
                    icon: Icon(Icons.save_alt_rounded, color: Colors.amber),
                    label: Text("Save", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
