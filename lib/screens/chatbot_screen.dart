import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/xp_toast.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  _ChatbotScreenState createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  List<Map<String, dynamic>> _history = [];
  String? _targetRole;
  List<String> _missingSkills = [];
  List _userSkills = [];
  String _userName = 'there';
  String _experienceSummary = '';
  String _educationSummary = '';
  String _userId = '';

  @override
  void initState() {
    super.initState();
    _loadContext();
  }

  Future _loadContext() async {
    final prefs = await SharedPreferences.getInstance();
    final us = prefs.getString('extracted_skills') ?? '';
    final userName = prefs.getString('user_name') ?? 'there';
    final userId = prefs.getString('user_id') ?? '';
    final experienceSummary = prefs.getString('experience_summary') ?? '';
    final educationSummary = prefs.getString('education_summary') ?? '';

    setState(() {
      _targetRole = prefs.getString('target_role');
      final s = prefs.getString('missing_skills') ?? '';
      _missingSkills = s.isEmpty ? [] : s.split(',');
      _userSkills = us.isEmpty ? [] : us.split(',');
      _userName = userName;
      _userId = userId;
      _experienceSummary = experienceSummary;
      _educationSummary = educationSummary;
    });

    // Load chat history
    if (userId.isNotEmpty) {
      await _loadChatHistory(userId);
    }
  }

  Future<void> _loadChatHistory(String userId) async {
    try {
      final history = await ApiService.loadChatHistory(userId);
      if (mounted) {
        setState(() {
          _history = history.cast<Map<String, dynamic>>();
          // Populate messages from history
          for (final msg in history) {
            _messages.add({
              'sender': msg['role'] == 'user' ? 'user' : 'bot',
              'text': msg['content'] ?? '',
            });
          }
          // Show banner if history loaded
          if (history.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('💬 Resuming your previous conversation'),
                duration: Duration(seconds: 2),
              ),
            );
          } else {
            // Add greeting if no history
            _messages.add({
              'sender': 'bot',
              'text': 'Hi $_userName! 👋 I\'m your personal career coach. Ask me anything about your path to becoming a ${_targetRole ?? "developer"}!',
            });
          }
        });
      }
    } catch (_) {
      // Silent fail - show greeting instead
      if (mounted) {
        setState(() {
          _messages.add({
            'sender': 'bot',
            'text': 'Hi $_userName! 👋 I\'m your personal career coach. Ask me anything about your path to becoming a ${_targetRole ?? "developer"}!',
          });
        });
      }
    }
  }

  Future sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;
    _controller.clear();
    setState(() {
      _messages.add({'sender': 'user', 'text': text});
      _isLoading = true;
    });
    try {
      final result = await ApiService.sendChatMessage(
        message: text,
        targetRole: _targetRole,
        missingSkills: _missingSkills,
        userSkills: _userSkills,
        userName: _userName,
        experienceSummary: _experienceSummary,
        educationSummary: _educationSummary,
        history: _history,
      );
      final reply = result['reply'] ?? 'Sorry, I could not respond.';
      final updated = result['updated_history'] as List? ?? [];
      _history = updated
          .map((m) => {
                'role': m['role'].toString(),
                'content': m['content'].toString()
              })
          .toList();
      setState(() {
        _messages.add({'sender': 'bot', 'text': reply});
        _isLoading = false;
      });

      // Save chat history and award XP in background
      if (_userId.isNotEmpty) {
        ApiService.saveChatHistory(_userId, _history).ignore();
        ApiService.awardXP(_userId, 'chat_message_sent').then((xpResult) {
          if (mounted && xpResult != null && xpResult['action_xp'] != null) {
            XpToast.show(
              context,
              xp: xpResult['action_xp'] as int,
              action: 'chat_message_sent',
            );
          }
        }).catchError((_) {});
      }
    } catch (e) {
      setState(() {
        _messages.add({
          'sender': 'bot',
          'text': 'Connection error. Is the backend running?'
        });
        _isLoading = false;
      });
    }
  }

  Future<void> _clearChatHistory() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Clear chat history?'),
        content: Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() {
                _messages.clear();
                _history.clear();
              });
              if (_userId.isNotEmpty) {
                await ApiService.saveChatHistory(_userId, []);
              }
            },
            child: Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget buildMessage(Map<String, String> msg) {
    bool isUser = msg['sender'] == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 6),
        padding: EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? Color(0xFFE4D6FF) : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(msg['text']!, style: TextStyle(color: Colors.black87)),
      ),
    );
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
            Text("Career Chatbot"),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _clearChatHistory,
            tooltip: 'Clear chat history',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: EdgeInsets.symmetric(vertical: 6),
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SizedBox(
                        width: 36,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF140536),
                        ),
                      ),
                    ),
                  );
                }
                return buildMessage(_messages[index]);
              },
            ),
          ),
          Divider(height: 1),
          Container(
            color: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Ask something about your career...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: sendMessage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF140536), // Dark Purple
                    padding: EdgeInsets.all(14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Icon(Icons.send),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
