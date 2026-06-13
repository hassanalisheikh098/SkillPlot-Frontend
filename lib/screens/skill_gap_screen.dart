import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'course_recommendation_screen.dart';
import 'roadmap_screen.dart';
import '../widgets/skill_chip.dart';
import '../widgets/sp_loader.dart';
import '../widgets/xp_toast.dart';

class SkillGapScreen extends StatefulWidget {
  @override
  _SkillGapScreenState createState() => _SkillGapScreenState();
}

class _SkillGapScreenState extends State<SkillGapScreen> {
  String? _selectedRole;
  List<String> _jobRoles = [];
  Map<String, int> _roleSkillCounts = {};
  List<String> _userSkills = [];
  Map _result = {};
  bool _loadingRoles = true;
  bool _analyzing = false;

  Color _getReadinessColor(int score) {
    if (score < 40) return Colors.red;
    if (score < 70) return Colors.orange;
    if (score < 90) return Colors.blue;
    return Colors.green;
  }

  String _getReadinessMessage(int score) {
    if (score < 40) return 'Significant prep needed';
    if (score < 70) return 'Making good progress';
    if (score < 90) return 'Almost ready!';
    return 'You\'re job-ready! 🎉';
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var saved = prefs.getString('extracted_skills') ?? '';

      if (saved.isEmpty) {
        final userId = prefs.getString('user_id') ?? '';
        if (userId.isNotEmpty) {
          try {
            final profile = await ApiService.getResumeProfile(userId);
            if (profile['status'] != 'not_found') {
              final skills = profile['extracted_skills'] as List? ?? [];
              saved = skills.cast<String>().join(',');
              if (saved.isNotEmpty) {
                await prefs.setString('extracted_skills', saved);
              }
            }
          } catch (_) {}
        }
      }

      if (saved.isNotEmpty) {
        _userSkills = saved.split(',');
      }

      final roles = await ApiService.getJobRoles();
      List<String> normalizedRoles = [];
      Map<String, int> skillCounts = {};
      
      if (roles is List) {
        normalizedRoles = roles.map((role) => role.toString()).toList();
      } else if (roles is Map && roles['roles'] is List) {
        normalizedRoles = roles['roles'].cast<String>();
        if (roles['skill_counts'] is Map) {
          skillCounts = Map<String, int>.from(
            (roles['skill_counts'] as Map).map(
              (k, v) => MapEntry(k.toString(), (v as num).toInt()),
            ),
          );
        }
      }

      setState(() {
        _jobRoles = normalizedRoles;
        _roleSkillCounts = skillCounts;
        _loadingRoles = false;
      });
    } catch (e) {
      setState(() => _loadingRoles = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load job roles. Check connection.')),
      );
    }
  }

  Future _analyze() async {
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a job role first.')),
      );
      return;
    }

    setState(() => _analyzing = true);
    try {
      final result = await ApiService.analyzeGap(_selectedRole!, _userSkills);
      setState(() => _result = result);

      final prefs = await SharedPreferences.getInstance();
      final missing = List<String>.from(
        (result['missing_skills'] ?? []).map((skill) => skill.toString()),
      );
      await prefs.setString('missing_skills', missing.join(','));
      await prefs.setString('target_role', _selectedRole!);

      final userId = prefs.getString('user_id') ?? '';
      if (userId.isNotEmpty) {
        ApiService.awardXP(userId, 'skill_gap_analyzed').then((xpResult) {
          if (mounted && xpResult != null && xpResult['action_xp'] != null) {
            XpToast.show(
              context,
              xp: xpResult['action_xp'] as int,
              action: 'skill_gap_analyzed',
            );
          }
        }).catchError((_) {});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Analysis failed. Try again.')),
      );
    } finally {
      setState(() => _analyzing = false);
    }
  }

  List<DropdownMenuItem<String>> _buildRoleItems() {
    return _jobRoles.map<DropdownMenuItem<String>>((role) {
      final roleText = role is String ? role : role.toString();
      return DropdownMenuItem<String>(
        value: roleText,
        child: Text(roleText),
      );
    }).toList();
  }

  List<String> _asStringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Color(0xFF140536),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Image.asset('assets/images/background.png', width: 32),
            SizedBox(width: 12),
            Text("Skill Gap Analyzer"),
          ],
        ),
      ),
      body: _loadingRoles
          ? const SpLoader(message: 'Loading job roles...')
          : SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_userSkills.isEmpty)
                    Container(
                      padding: EdgeInsets.all(12),
                      margin: EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Upload your resume first for accurate results.",
                              style: TextStyle(color: Colors.orange.shade800),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Text(
                    "Your resume skills: ${_userSkills.length} detected",
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Select Target Job Role",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    hint: Text("Choose a job role"),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Color(0xFF140536)),
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    items: _jobRoles
                        .map<DropdownMenuItem<String>>((role) {
                          final count = _roleSkillCounts[role] ?? 0;
                          return DropdownMenuItem<String>(
                            value: role,
                            child: Text('$role ($count skills)'),
                          );
                        })
                        .toList(),
                    onChanged: (val) => setState(() => _selectedRole = val),
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF140536),
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _analyzing ? null : _analyze,
                      child: _analyzing
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              "Analyze Skill Gap",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16),
                            ),
                    ),
                  ),
                  if (_result.isNotEmpty) ...[
                    SizedBox(height: 24),
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 8),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              "${_result['readiness_score'] ?? 0}%",
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: _getReadinessColor(
                                  (_result['readiness_score'] ?? 0) as int,
                                ),
                              ),
                            ),
                          ),
                          Center(
                            child: Text(
                              "Job Readiness Score (${_result['total_required'] ?? 0} required skills)",
                              style: TextStyle(color: Colors.black54),
                            ),
                          ),
                          SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: (((_result['readiness_score'] ?? 0) as num) /
                                    100)
                                .toDouble(),
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getReadinessColor(
                                (_result['readiness_score'] ?? 0) as int,
                              ),
                            ),
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          SizedBox(height: 8),
                          Center(
                            child: Text(
                              _getReadinessMessage(
                                (_result['readiness_score'] ?? 0) as int,
                              ),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _getReadinessColor(
                                  (_result['readiness_score'] ?? 0) as int,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          Text(
                            "✅ Matched Skills",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: _asStringList(_result['matched_skills'])
                                .map(
                                  (s) => SkillChip(skill: s, isMatched: true),
                                )
                                .toList(),
                          ),
                          SizedBox(height: 16),
                          Text(
                            "❌ Missing Skills",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: _asStringList(_result['missing_skills'])
                                .map(
                                  (s) => SkillChip(skill: s, isMissing: true),
                                )
                                .toList(),
                          ),
                          if (_asStringList(_result['missing_skills']).isNotEmpty) ...[
                            SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    icon: Icon(Icons.school),
                                    label: Text("Get Courses"),
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CourseRecommendationScreen(),
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF140536),
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: Icon(Icons.map),
                                    label: Text("View Roadmap"),
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => RoadmapScreen(),
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Color(0xFF140536),
                                      side: BorderSide(color: Color(0xFF140536)),
                                      padding: EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
