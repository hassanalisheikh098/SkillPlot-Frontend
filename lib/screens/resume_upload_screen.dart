import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/skill_chip.dart';
import '../widgets/xp_toast.dart';

class ResumeUploadScreen extends StatefulWidget {
  const ResumeUploadScreen({super.key});

  @override
  _ResumeUploadScreenState createState() => _ResumeUploadScreenState();
}

class _ResumeUploadScreenState extends State<ResumeUploadScreen> {

  // ✅ STATIC VARIABLES
  static String? fileName;
  static File? selectedFile;
  Uint8List? selectedBytes;
  List _extractedSkills = [];
  String? _experienceSummary;
  String? _educationSummary;
  bool _hasResumeOnFile = false;

  @override
  void initState() {
    super.initState();
    _loadSavedResume();
  }

  Future<void> _loadSavedResume() async {
    final prefs = await SharedPreferences.getInstance();
    final hasResume = prefs.getString('has_resume') == 'true';
    final savedFileName = prefs.getString('resume_filename');
    final savedSkills = prefs.getString('extracted_skills') ?? '';
    final exp = prefs.getString('experience_summary') ?? '';
    final edu = prefs.getString('education_summary') ?? '';

    if (mounted) {
      setState(() {
        _hasResumeOnFile = hasResume;
        if (hasResume && savedFileName != null) {
          fileName = savedFileName;
        }
        if (savedSkills.isNotEmpty) {
          _extractedSkills = savedSkills.split(',');
        }
        _experienceSummary = exp.isNotEmpty ? exp : null;
        _educationSummary = edu.isNotEmpty ? edu : null;
      });
    }
  }

  // 📁 Function to pick + upload resume
  Future<void> pickResume() async {

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      final pickedFile = result.files.single;

      // ✅ SAVE FILE
      fileName = pickedFile.name;
      selectedBytes = pickedFile.bytes;
      if (!kIsWeb && pickedFile.path != null) {
        selectedFile = File(pickedFile.path!);
      }

      setState(() {});

      try {
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('user_id') ?? '';

        final result = await ApiService.uploadResume(
          file: selectedFile,
          bytes: selectedBytes,
          filename: fileName!,
          userId: userId,
        );
        final skills = List.from(result['extracted_skills'] ?? []);

        // Save all fields to prefs
        await prefs.setString('extracted_skills', skills.join(','));
        await prefs.setString('has_resume', 'true');
        await prefs.setString('resume_filename', fileName ?? '');
        await prefs.setString('user_name', result['full_name'] ?? '');
        await prefs.setString('experience_summary', result['experience_summary'] ?? '');
        await prefs.setString('education_summary', result['education_summary'] ?? '');

        setState(() {
          _extractedSkills = skills;
          _hasResumeOnFile = true;
          _experienceSummary = result['experience_summary'];
          _educationSummary = result['education_summary'];
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Resume uploaded! Found ${skills.length} skills ✅"),
          ),
        );

        if (userId.isNotEmpty) {
          ApiService.awardXP(userId, 'resume_uploaded').then((xpResult) {
            if (mounted && xpResult != null && xpResult['action_xp'] != null) {
              XpToast.show(
                context,
                xp: xpResult['action_xp'] as int,
                action: 'resume_uploaded',
              );
            }
          }).catchError((_) {});
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload error: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: Color(0xFFF4F6FA),

      appBar: AppBar(

        title: Row(
          children: [

            Image.asset(
              'assets/images/background.png',
              width: 32,
            ),

            SizedBox(width: 12),

            Text("Upload Resume"),
          ],
        ),

        backgroundColor: Color(0xFF140536),
        foregroundColor: Colors.white,
      ),

      body: Padding(

        padding: const EdgeInsets.all(24.0),

        child: Container(

          padding: EdgeInsets.all(24),

          decoration: BoxDecoration(

            color: Colors.white,

            borderRadius: BorderRadius.circular(16),

            boxShadow: [

              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),

          child: SingleChildScrollView(
            child: Column(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

              Text(
                "Let’s get started with your resume",

                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),

              SizedBox(height: 16),

              Text(
                "Upload your latest resume. We’ll analyze it and help you improve it.",

                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              SizedBox(height: 16),

              // ✅ Resume on file banner
              if (_hasResumeOnFile)
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFFD4EDDA),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Color(0xFFC3E6CB)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Resume on file: $fileName — uploaded previously. You can replace it below.",
                          style: TextStyle(fontSize: 13, color: Color(0xFF155724)),
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: 32),

              // 📎 Upload Button
              GestureDetector(

                onTap: pickResume,

                child: Container(

                  padding: EdgeInsets.symmetric(vertical: 18),

                  width: double.infinity,

                  decoration: BoxDecoration(
                    color: Color(0xFF4B0082),
                    borderRadius: BorderRadius.circular(8),
                  ),

                  child: Center(

                    child: Text(
                      "Choose & Upload Resume",

                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

              // ✅ FILE NAME SHOW
              if (fileName != null) ...[

                SizedBox(height: 24),

                Container(

                  padding: EdgeInsets.all(14),

                  width: double.infinity,

                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.indigo.shade200,
                    ),
                  ),

                  child: Row(

                    children: [

                      Icon(
                        Icons.description,
                        color: Colors.indigo,
                      ),

                      SizedBox(width: 10),

                      Expanded(
                        child: Text(
                          fileName!,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (_extractedSkills.isNotEmpty) ...[
                SizedBox(height: 20),
                Text(
                  "Skills Detected (${_extractedSkills.length})",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: _extractedSkills
                      .map((skill) => SkillChip(skill: skill))
                      .toList(),
                ),
              ],

              // 📋 Experience and Education Section
              if (_experienceSummary != null || _educationSummary != null)
                Container(
                  margin: EdgeInsets.only(top: 16),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFFF0EBFF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_experienceSummary != null && _experienceSummary!.isNotEmpty) ...[
                        Text(
                          "📋 Experience Detected",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4B0082),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          _experienceSummary!,
                          style: TextStyle(fontSize: 13, color: Colors.black87),
                        ),
                      ],
                      if (_experienceSummary != null &&
                          _experienceSummary!.isNotEmpty &&
                          _educationSummary != null &&
                          _educationSummary!.isNotEmpty)
                        SizedBox(height: 12),
                      if (_educationSummary != null && _educationSummary!.isNotEmpty) ...[
                        Text(
                          "🎓 Education Detected",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4B0082),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          _educationSummary!,
                          style: TextStyle(fontSize: 13, color: Colors.black87),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}