import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/sp_loader.dart';
import '../widgets/xp_toast.dart';

class RoadmapScreen extends StatefulWidget {
  @override
  _RoadmapScreenState createState() => _RoadmapScreenState();
}

class _RoadmapScreenState extends State<RoadmapScreen> {
  List _steps = [];
  bool _loading = false;
  String _targetRole = 'Software Developer';
  List<String> _missingSkills = [];
  Set _completedSteps = {};

  @override
  void initState() {
    super.initState();
    _loadAndGenerate();
  }

  Future _loadAndGenerate() async {
    final prefs = await SharedPreferences.getInstance();
    _targetRole = prefs.getString('target_role') ?? 'Software Developer';
    final s = prefs.getString('missing_skills') ?? '';
    _missingSkills = s.isEmpty ? [] : s.split(',');
    final completedJson = prefs.getString('roadmap_completed_$_targetRole') ?? '[]';
    final List decoded = jsonDecode(completedJson);
    setState(() => _completedSteps = Set.from(decoded.cast()));
    await _generate();
  }

  Future _generate() async {
    setState(() => _loading = true);
    try {
      final result = await ApiService.generateRoadmap(_targetRole, _missingSkills);
      setState(() {
        _steps = result['steps'] ?? [];
        _loading = false;
      });
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? '';
      if (userId.isNotEmpty) {
        ApiService.awardXP(userId, 'roadmap_generated').then((xpResult) {
          if (mounted && xpResult != null && xpResult['action_xp'] != null) {
            XpToast.show(
              context,
              xp: xpResult['action_xp'] as int,
              action: 'roadmap_generated',
            );
          }
        }).catchError((_) {});
      }
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate roadmap. Try again.')),
      );
    }
  }

  Future _toggleStep(int stepNum) async {
    setState(() {
      if (_completedSteps.contains(stepNum)) {
        _completedSteps.remove(stepNum);
      } else {
        _completedSteps.add(stepNum);
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'roadmap_completed_$_targetRole',
      jsonEncode(_completedSteps.toList()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Color(0xFF140536),
        foregroundColor: Colors.white,
        title: Row(children: [
          Image.asset('assets/images/background.png', width: 32),
          SizedBox(width: 12),
          Text("Career Roadmap"),
        ]),
      ),
      body: _loading
          ? const SpLoader(message: 'Generating your AI roadmap...')
          : _steps.isEmpty
              ? Center(child: Text("No roadmap yet. Run Skill Gap Analysis first."))
              : Column(
                  children: [
                    if (_steps.isNotEmpty)
                      LinearProgressIndicator(
                        value: _steps.isEmpty
                            ? 0
                            : _completedSteps.length / _steps.length,
                        backgroundColor: Colors.grey[200],
                        color: Colors.green,
                        minHeight: 5,
                      ),
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: _steps.length,
                        itemBuilder: (context, index) {
                          final step = _steps[index];
                          final stepNum = step['step_number'] ?? index + 1;
                          return Container(
                            margin: EdgeInsets.only(bottom: 16),
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _completedSteps.contains(stepNum)
                                  ? const Color(0xFFE8F5E9)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(color: Colors.black12, blurRadius: 6),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Color(0xFF140536),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$stepNum',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        step['title'] ?? '',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        step['description'] ?? '',
                                        style: TextStyle(
                                          color: Colors.black54,
                                          fontSize: 13,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.schedule, size: 14, color: Colors.grey),
                                          SizedBox(width: 4),
                                          Text(
                                            "~${step['estimated_weeks']} weeks",
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: List.from(step['resources'] ?? [])
                                            .map((r) {
                                              final urlStr = r.toString();
                                              final displayText = urlStr.length > 30
                                                  ? '${urlStr.substring(0, 30)}…'
                                                  : urlStr;
                                              return ActionChip(
                                                label: Text(
                                                  displayText,
                                                  style: TextStyle(fontSize: 11),
                                                ),
                                                backgroundColor: Color(0xFFE4D6FF),
                                                labelStyle:
                                                    TextStyle(color: Color(0xFF4B0082)),
                                                padding: EdgeInsets.zero,
                                                materialTapTargetSize:
                                                    MaterialTapTargetSize.shrinkWrap,
                                                onPressed: () async {
                                                  final uri = Uri.tryParse(urlStr);
                                                  if (uri != null && await canLaunchUrl(uri)) {
                                                    launchUrl(
                                                      uri,
                                                      mode: LaunchMode.externalApplication,
                                                    );
                                                  }
                                                },
                                              );
                                            })
                                            .toList(),
                                      ),
                                    ],
                                  ),
                                ),
                                Checkbox(
                                  value: _completedSteps.contains(stepNum),
                                  activeColor: Colors.green,
                                  visualDensity: VisualDensity.compact,
                                  onChanged: (_) => _toggleStep(stepNum),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Color(0xFF140536),
        icon: Icon(Icons.refresh, color: Colors.white),
        label: Text("Regenerate", style: TextStyle(color: Colors.white)),
        onPressed: _generate,
      ),
    );
  }
}
