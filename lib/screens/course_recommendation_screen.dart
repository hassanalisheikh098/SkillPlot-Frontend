import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'skill_gap_screen.dart';

class CourseRecommendationScreen extends StatefulWidget {
  const CourseRecommendationScreen({super.key});

  @override
  State<CourseRecommendationScreen> createState() => _CourseRecommendationScreenState();
}

class _CourseRecommendationScreenState extends State<CourseRecommendationScreen> {
  List _courses = [];
  bool _loading = true;
  String _errorMsg = '';

  @override
  void initState() {
    super.initState();
    _loadCourses();
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
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : _errorMsg.isNotEmpty
              ? Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1F1B3A),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            _errorMsg.contains('No skill gaps')
                                ? Icons.analytics_outlined
                                : Icons.wifi_off_rounded,
                            size: 64,
                            color: Colors.deepPurpleAccent[100],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _errorMsg,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _errorMsg.contains('No skill gaps')
                              ? 'We need to know your skill gaps before recommending tailored courses.'
                              : 'We couldn\'t connect to our servers. Please check your internet connection and try again.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: () {
                            if (_errorMsg.contains('No skill gaps')) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SkillGapScreen(),
                                ),
                              );
                            } else {
                              setState(() {
                                _loading = true;
                                _errorMsg = '';
                              });
                              _loadCourses();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE4D6FF),
                            foregroundColor: const Color(0xFF4B0082),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 4,
                          ),
                          icon: Icon(
                            _errorMsg.contains('No skill gaps')
                                ? Icons.arrow_forward
                                : Icons.refresh,
                          ),
                          label: Text(
                            _errorMsg.contains('No skill gaps')
                                ? 'Go to Skill Gap Analysis'
                                : 'Try Again',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
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
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _courses.length,
                            itemBuilder: (context, index) {
                              final course = _courses[index];
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
