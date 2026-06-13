import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CourseCompletionScreen extends StatefulWidget {
  const CourseCompletionScreen({super.key});

  @override
  _CourseCompletionScreenState createState() => _CourseCompletionScreenState();
}

class _CourseCompletionScreenState extends State<CourseCompletionScreen> {
  List<Map<String, dynamic>> courses = [];
  bool _loadingCourses = true;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future _loadCourses() async {
    final prefs = await SharedPreferences.getInstance();

    final completionJson = prefs.getString('course_completion_state') ?? '{}';
    final Map completionState = jsonDecode(completionJson);

    final savedJson = prefs.getString('recommended_courses') ?? '';
    List<Map<String, dynamic>> loaded = [];

    if (savedJson.isNotEmpty) {
      final List decoded = jsonDecode(savedJson);
      loaded = decoded.map<Map<String, dynamic>>((c) => {
            'title': c['course_title'] ?? c['title'] ?? 'Course',
            'skill': c['skill'] ?? '',
            'completed': completionState[c['course_title'] ?? ''] ?? false,
          }).toList();
    }

    if (loaded.isEmpty) {
      loaded = [
        {
          'title': 'Go to Course Recommendations first, then come back here.',
          'skill': '',
          'completed': false,
        }
      ];
    }

    setState(() {
      courses = loaded;
      _loadingCourses = false;
    });
  }

  Future toggleCompletion(int index) async {
    setState(() {
      courses[index]['completed'] = !courses[index]['completed'];
    });

    // Only award XP when marking as complete (not when unchecking)
    if (courses[index]['completed'] == true) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('user_id') ?? '';
        if (userId.isNotEmpty) {
          final result = await ApiService.awardXP(userId, 'course_completed');
          final xp = result['action_xp'] ?? 100;
          final newBadges = List.from(result['new_badges'] ?? []);
          String msg = "+$xp XP earned! 🎉";
          if (newBadges.isNotEmpty) msg += "  New badge: ${newBadges.first} 🏅";
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: Color(0xFF4B0082),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        // Silent fail — completion is still recorded locally
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final Map state = {
      for (var c in courses) (c['title'] as String): c['completed'],
    };
    await prefs.setString('course_completion_state', jsonEncode(state));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF140536).withValues(alpha: 0.85), // ✅ Background with opacity
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Color(0xFF140536).withValues(alpha: 0.85), // ✅ AppBar with opacity
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Image.asset('assets/images/background.png', width: 36),
            SizedBox(width: 16),
            Text("Mark Course Completion"),
          ],
        ),
      ),
      body: _loadingCourses
          ? Center(child: CircularProgressIndicator(color: Color(0xFF140536)))
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
                      "Completed Your Courses?",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      "Mark any course below that you’ve successfully completed.",
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                    SizedBox(height: 24),
                    Expanded(
                      child: ListView.builder(
                        itemCount: courses.length,
                        itemBuilder: (context, index) {
                          final course = courses[index];
                          return CheckboxListTile(
                            title: Text(course['title']),
                            subtitle: (course['skill'] as String).isNotEmpty
                                ? Text(
                                    'Skill: ${course['skill']}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black45,
                                    ),
                                  )
                                : null,
                            value: course['completed'],
                            activeColor: Color(0xFF140536), // Dark purple
                            onChanged: (_) => toggleCompletion(index),
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
