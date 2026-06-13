import 'package:flutter/material.dart';
import 'package:sp_app/screens/learning_dashboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_store.dart';
import 'login_screen.dart';
import 'resume_upload_screen.dart';
import 'skill_gap_screen.dart';
import 'roadmap_screen.dart';
import 'course_recommendation_screen.dart';
import 'course_completion_screen.dart';
import 'chatbot_screen.dart';
import 'job_alerts_screen.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _userName = 'there';
  int _totalXp = 0;
  String _currentBadge = 'Beginner';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString('user_name') ?? 'there';
      final userId = prefs.getString('user_id') ?? '';

      setState(() => _userName = userName);

      if (userId.isNotEmpty) {
        final progress = await ApiService.getProgress(userId);
        if (mounted) {
          setState(() {
            _totalXp = progress['total_xp'] ?? 0;
            final badges = progress['badges'] as List? ?? [];
            _currentBadge = badges.isNotEmpty ? badges.last : 'Beginner';
          });
        }
      }
    } catch (_) {
      // Silently fail
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF140536),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        child: CustomScrollView(
          slivers: [
            // Custom AppBar with greeting
            SliverAppBar(
              backgroundColor: Color(0xFF140536),
              elevation: 0,
              pinned: true,
              expandedHeight: 80,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: Color(0xFF140536),
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Image.asset('assets/images/background.png', width: 40),
                          SizedBox(width: 12),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hi, $_userName 👋',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Welcome back',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      PopupMenuButton(
                        icon: Icon(Icons.more_vert, color: Colors.white),
                        onSelected: (value) async {
                          if (value == 'logout') {
                            await UserStore.logout();
                            if (context.mounted) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (_) => const LoginScreen()),
                                (route) => false,
                              );
                            }
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'logout',
                            child: Row(
                              children: [
                                Icon(Icons.logout, size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Logout'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // XP Progress Card (pinned)
            SliverPersistentHeader(
              pinned: true,
              delegate: _XpHeaderDelegate(xp: _totalXp, badge: _currentBadge),
            ),
            // Grid of tiles
            SliverPadding(
              padding: EdgeInsets.all(12),
              sliver: SliverGrid.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: [
                  _buildTile(
                    context,
                    Icons.upload_file,
                    "Upload Resume",
                    ResumeUploadScreen(),
                  ),
                  _buildTile(
                    context,
                    Icons.analytics,
                    "Skill Gap Analysis",
                    SkillGapScreen(),
                  ),
                  _buildTile(
                    context,
                    Icons.map_outlined,
                    "Career Roadmap",
                    RoadmapScreen(),
                  ),
                  _buildTile(
                    context,
                    Icons.school,
                    "Course Recommendations",
                    CourseRecommendationScreen(),
                  ),
                  _buildTile(
                    context,
                    Icons.check_circle,
                    "Mark Completion",
                    CourseCompletionScreen(),
                  ),
                  _buildTile(context, Icons.route, "ChatBot", ChatbotScreen()),
                  _buildTile(
                    context,
                    Icons.leaderboard,
                    "Learning Dashboard",
                    LearningDashboardScreen(),
                  ),
                  _buildTile(context, Icons.work, "Job Alerts", JobAlertsScreen()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(
    BuildContext context,
    IconData icon,
    String label,
    Widget screen,
  ) {
    return GestureDetector(
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFF1F1B3A),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.deepPurpleAccent[100], size: 30),
            SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white, fontSize: 13.5),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom header delegate for XP card
class _XpHeaderDelegate extends SliverPersistentHeaderDelegate {
  final int xp;
  final String badge;

  _XpHeaderDelegate({required this.xp, required this.badge});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final nextLevelXp = ((xp ~/ 500) + 1) * 500;
    final progress = (xp % 500) / 500;

    return Container(
      color: Color(0xFF140536),
      padding: EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1F1B3A), Color(0xFF2D1B69)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events, color: Colors.amber, size: 24),
                SizedBox(width: 8),
                Text(
                  '$xp XP',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 20),
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(color: Colors.amber, fontSize: 12),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(Colors.amber),
              minHeight: 6,
            ),
            SizedBox(height: 8),
            Text(
              'Next level at $nextLevelXp XP',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  @override
  double get maxExtent => 200;
  @override
  double get minExtent => 200;

  @override
  bool shouldRebuild(_XpHeaderDelegate oldDelegate) =>
      oldDelegate.xp != xp || oldDelegate.badge != badge;
}
