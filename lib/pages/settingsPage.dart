import 'package:flutter/material.dart';
import 'package:study_forge/components/sideBar.dart';
import 'package:study_forge/themes/forge_colors.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isDarkMode = false;
  bool _limitMemoryPersistence = true;
  double _pdfTokenLimit = 1000; // future-proof slider for PDF memory limits

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
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
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
              color: ForgeColors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: ListView(
          children: [
            _buildSectionTitle("General"),
            SwitchListTile(
              title: Text("Dark Mode", style: ForgeTextStyles.tileTitle),
              subtitle: Text(
                "Switch between light and dark themes",
                style: ForgeTextStyles.tileSubtitle,
              ),
              value: _isDarkMode,
              activeColor: ForgeColors.amber300,
              onChanged: (value) {
                setState(() {
                  _isDarkMode = value;
                });
                // TODO: Apply theme across app
              },
            ),
            ListTile(
              leading: Icon(Icons.language, color: ForgeColors.amber),
              title: Text("Language", style: ForgeTextStyles.tileTitle),
              subtitle: Text(
                "English (US)",
                style: ForgeTextStyles.tileSubtitle,
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                color: ForgeColors.amber100,
                size: 18,
              ),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(
                Icons.notifications_active_outlined,
                color: ForgeColors.amber,
              ),
              title: Text("Notifications", style: ForgeTextStyles.tileTitle),
              subtitle: Text(
                "Push, Email",
                style: ForgeTextStyles.tileSubtitle,
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                color: ForgeColors.amber100,
                size: 18,
              ),
              onTap: () {},
            ),
            const Divider(),
            _buildSectionTitle("Memory"),
            SwitchListTile(
              title: Text(
                "Limit AI Memory Persistence",
                style: ForgeTextStyles.tileTitle,
              ),
              subtitle: Text(
                "Resets memory context after each chat.",
                style: ForgeTextStyles.tileSubtitle,
              ),
              value: _limitMemoryPersistence,
              activeColor: ForgeColors.amber300,
              onChanged: (value) {
                setState(() {
                  _limitMemoryPersistence = value;
                });
                // TODO: Hook this into Ember's memory handler
              },
            ),
            if (_limitMemoryPersistence) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Text(
                      "PDF Token Limit:",
                      style: ForgeTextStyles.tileSubtitle,
                    ),
                    Expanded(
                      child: Slider(
                        value: _pdfTokenLimit,
                        min: 500,
                        max: 4000,
                        divisions: 7,
                        label: _pdfTokenLimit.round().toString(),
                        activeColor: ForgeColors.amber300,
                        onChanged: (value) {
                          setState(() {
                            _pdfTokenLimit = value;
                          });
                          // TODO: Use this to cap token extraction
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
            ListTile(
              leading: Icon(Icons.memory, color: ForgeColors.amber),
              title: Text("AI Model", style: ForgeTextStyles.tileTitle),
              subtitle: Text("Ember 3.3", style: ForgeTextStyles.tileSubtitle),
              trailing: Icon(
                Icons.arrow_forward_ios,
                color: ForgeColors.amber100,
                size: 18,
              ),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.security, color: ForgeColors.amber),
              title: Text("Privacy Settings", style: ForgeTextStyles.tileTitle),
              subtitle: Text(
                "Manage data & permissions",
                style: ForgeTextStyles.tileSubtitle,
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                color: ForgeColors.amber100,
                size: 18,
              ),
              onTap: () {},
            ),
            const Divider(),
            _buildSectionTitle("About"),
            ListTile(
              leading: Icon(Icons.info_outline, color: ForgeColors.amber),
              title: Text("App Version", style: ForgeTextStyles.tileTitle),
              subtitle: Text(
                "StudyForge v1.1.5+15",
                style: ForgeTextStyles.tileSubtitle,
              ),
              trailing: Icon(
                Icons.copyright,
                color: ForgeColors.amber100,
                size: 18,
              ),
              onTap: () {
                // TODO: Open about dialog or credits
              },
            ),
            ListTile(
              leading: Icon(Icons.help_outline, color: ForgeColors.amber),
              title: Text("Help & Support", style: ForgeTextStyles.tileTitle),
              subtitle: Text(
                "FAQ, Contact, Feedback",
                style: ForgeTextStyles.tileSubtitle,
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                color: ForgeColors.amber100,
                size: 18,
              ),
              onTap: () {},
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
