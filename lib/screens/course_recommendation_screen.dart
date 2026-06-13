import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class CourseRecommendationScreen extends StatefulWidget {
  const CourseRecommendationScreen({super.key});

  @override
  State<CourseRecommendationScreen> createState() => _CourseRecommendationScreenState();
}

class _CourseRecommendationScreenState extends State<CourseRecommendationScreen> {
  List _courses = [];
  bool _loading = true;
  String _errorMsg = '';
  String _selectedProvider = 'All';

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  List get _filteredCourses {
    if (_selectedProvider == 'All') return _courses;
    return _courses
        .where((c) => (c['provider'] ?? '')
            .toString()
            .toLowerCase()
            .contains(_selectedProvider.toLowerCase()))
        .toList();
  }

  Future _loadCourses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('missing_skills') ?? '';
      final List<String> missing = saved.isEmpty ? [] : saved.split(',');
      if (missing.isEmpty) {
        setState(() {
          _loading = false;
          _errorMsg = 'No skill gaps found. Run Skill Gap Analysis first.';
        });
        return;
      }
      final result = await ApiService.getRecommendations(missing);
      setState(() {
        _courses = result['recommendations'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMsg = 'Failed to load courses. Check connection.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF140536),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Color(0xFF140536),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Image.asset('assets/images/background.png', width: 36),
            SizedBox(width: 16),
            Text("Recommended Courses"),
          ],
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _errorMsg.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      _errorMsg,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54, fontSize: 15),
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Courses Just For You",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          "These courses can help you fill the skill gaps for your dream job:",
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: ['All', 'Udemy', 'Coursera', 'YouTube']
                                .map((provider) => Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: FilterChip(
                                        label: Text(provider, style: const TextStyle(fontSize: 12)),
                                        selected: _selectedProvider == provider,
                                        selectedColor: const Color(0xFFE4D6FF),
                                        checkmarkColor: const Color(0xFF4B0082),
                                        labelStyle: TextStyle(
                                          color: _selectedProvider == provider
                                              ? const Color(0xFF4B0082)
                                              : Colors.black87,
                                        ),
                                        onSelected: (_) =>
                                            setState(() => _selectedProvider = provider),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _filteredCourses.length,
                            itemBuilder: (context, index) {
                              final course = _filteredCourses[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: ListTile(
                                  leading: Icon(Icons.school, color: Color(0xFF140536)),
                                  title: Text(course['course_title'] ?? ''),
                                  subtitle: Text(
                                    "Platform: ${course['provider'] ?? ''}  •  Skill: ${course['skill'] ?? ''}",
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(
                                      Icons.open_in_new,
                                      color: Color(0xFF140536),
                                      size: 20,
                                    ),
                                    onPressed: () async {
                                      final url = Uri.parse(course['url'] ?? '');
                                      if (await canLaunchUrl(url)) {
                                        launchUrl(
                                          url,
                                          mode: LaunchMode.externalApplication,
                                        );
                                      }
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
