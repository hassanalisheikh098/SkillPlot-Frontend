import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/sp_loader.dart';

class LearningDashboardScreen extends StatefulWidget {
  const LearningDashboardScreen({super.key});

  @override
  State<LearningDashboardScreen> createState() => _LearningDashboardScreenState();
}

class _LearningDashboardScreenState extends State<LearningDashboardScreen> {
  int _totalXp = 0;
  List<String> _badges = ['Beginner'];
  int _completedCourses = 0;
  bool _loading = true;
  List<Map<String, dynamic>> _xpHistory = [];
  String _userId = '';

  int _prevBadgeXp(int xp) {
    const thresholds = [100, 300, 600, 1000, 2000];
    int prev = 0;
    for (final t in thresholds) {
      if (xp < t) break;
      prev = t;
    }
    return prev;
  }

  int _nextBadgeXp(int xp) {
    const thresholds = [100, 300, 600, 1000, 2000];
    for (final t in thresholds) {
      if (xp < t) return t;
    }
    return 2000;
  }

  String _formatAction(String action) {
    return action
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  String _formatTime(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
      if (diff.inHours < 24) return '${diff.inHours} hours ago';
      if (diff.inDays < 7) return '${diff.inDays} days ago';
      return 'long ago';
    } catch (_) {
      return 'long ago';
    }
  }

  String _badgeEmoji(String badge) {
    switch (badge.toLowerCase()) {
      case 'beginner':
        return '🌱';
      case 'explorer':
        return '🔍';
      case 'learner':
        return '📚';
      case 'achiever':
        return '🎯';
      case 'pro':
        return '⚡';
      case 'expert':
        return '🏆';
      default:
        return '⭐';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? '';
      
      setState(() => _userId = userId);

      if (userId.isNotEmpty) {
        final result = await ApiService.getProgress(userId);
        final history = await ApiService.getXpHistory(userId);

        setState(() {
          _totalXp = result['total_xp'] ?? 0;
          _badges = List<String>.from(result['badges'] ?? ['Beginner']);
          _completedCourses = result['completed_courses'] ?? 0;
          _xpHistory = (history['history'] as List? ?? [])
              .cast<Map<String, dynamic>>()
              .take(5)
              .toList();
        });
      }
    } catch (_) {
      // Silent fail
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Widget _badgeCard(String badge, bool isLocked) {
    return Container(
      width: 80,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isLocked ? Colors.grey.shade300 : Color(0xFFE4D6FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            isLocked ? '🔒' : _badgeEmoji(badge),
            style: TextStyle(fontSize: 32),
          ),
          SizedBox(height: 8),
          Text(
            badge,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isLocked ? Colors.grey : Color(0xFF4B0082),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(IconData icon, String label, String value) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: Color(0xFF4B0082)),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF140536),
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentLevel = _totalXp ~/ 100;

    return Scaffold(
      backgroundColor: Color(0xFF140536),
      appBar: AppBar(
        backgroundColor: Color(0xFF140536),
        elevation: 0,
        title: Row(
          children: [
            Image.asset('assets/images/background.png', width: 36),
            SizedBox(width: 16),
            Text("Learning Dashboard", style: TextStyle(fontSize: 18)),
          ],
        ),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const SpLoader(message: 'Loading your progress...')
          : RefreshIndicator(
              onRefresh: _loadProgress,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // SECTION A: Hero XP Card
                    Container(
                      margin: EdgeInsets.all(16),
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF140536), Color(0xFF4B0082)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Level ${currentLevel}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '$_totalXp XP',
                            style: TextStyle(
                              fontSize: 44,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 16),
                          LinearProgressIndicator(
                            value: (_totalXp % 100) / 100,
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            valueColor: AlwaysStoppedAnimation(Colors.amber),
                            minHeight: 6,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Next level: ${(((currentLevel) + 1) * 100)} XP',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // SECTION B: Stats Row
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _statCard(Icons.school, 'Courses', '$_completedCourses'),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _statCard(
                              Icons.military_tech,
                              'Badge',
                              _badges.last,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _statCard(Icons.trending_up, 'Level', '$currentLevel'),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 24),

                    // SECTION C: Badges
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Badges Earned',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: ['Beginner', 'Explorer', 'Learner', 'Achiever', 'Pro', 'Expert'].map((badge) {
                                    final isLocked = !_badges.contains(badge);
                                    return Padding(
                                      padding: EdgeInsets.only(right: 12),
                                      child: _badgeCard(badge, isLocked),
                                    );
                                  }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 24),

                    // SECTION D: Recent Activity
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recent Activity',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 12),
                          if (_xpHistory.isEmpty)
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'No activity yet',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: _xpHistory.length,
                              itemBuilder: (context, index) {
                                final activity = _xpHistory[index];
                                return Container(
                                  margin: EdgeInsets.only(bottom: 8),
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                        size: 20,
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _formatAction(
                                                activity['action'] ?? 'Unknown',
                                              ),
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                            Text(
                                              _formatTime(
                                                activity['timestamp'] ?? '',
                                              ),
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.white70,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '+${activity['xp_awarded'] ?? 0} XP',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amber,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),

                    SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
