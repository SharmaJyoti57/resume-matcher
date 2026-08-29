import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const ResumeMatcherApp());
}

class ResumeMatcherApp extends StatelessWidget {
  const ResumeMatcherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Resume Matcher',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF4F46E5),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F8FC),
        textTheme: ThemeData.light().textTheme.apply(fontFamily: 'Roboto'),
      ),
      home: const MatcherHomePage(),
    );
  }
}

class MatchResult {
  final int matchScore;
  final List<String> matchedSkills;
  final List<String> missingSkills;
  final String feedback;

  MatchResult({
    required this.matchScore,
    required this.matchedSkills,
    required this.missingSkills,
    required this.feedback,
  });

  factory MatchResult.fromJson(Map<String, dynamic> json) {
    return MatchResult(
      matchScore: json['match_score'] ?? 0,
      matchedSkills: List<String>.from(json['matched_skills'] ?? []),
      missingSkills: List<String>.from(json['missing_skills'] ?? []),
      feedback: json['feedback'] ?? '',
    );
  }
}

class MatcherHomePage extends StatefulWidget {
  const MatcherHomePage({super.key});

  @override
  State<MatcherHomePage> createState() => _MatcherHomePageState();
}

class _MatcherHomePageState extends State<MatcherHomePage> {
  final _resumeController = TextEditingController();
  final _jdController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  MatchResult? _result;

  static const _systemPrompt = '''
You are a strict, realistic technical recruiter. Compare this resume against this job description critically — do not be generous. Most resumes have some gaps; find them honestly.

Rules:
- match_score should rarely exceed 85 unless the resume is a near-perfect literal match to every single requirement listed.
- missing_skills must include anything mentioned in the job description that is not clearly evidenced in the resume, even minor ones (e.g. specific years of experience, specific tools, soft skills explicitly requested).
- Do not pad matched_skills with generic resume content that isn't specifically relevant to this job description's actual requirements.
- feedback must include at least one honest, specific area for improvement — never say the resume has no weaknesses.

Return ONLY valid JSON, no text before or after, in this exact format:
{
  "match_score": <0-100>,
  "matched_skills": ["skill1", "skill2"],
  "missing_skills": ["skill1", "skill2"],
  "feedback": "2-3 specific sentences including at least one real gap or improvement"
}
''';

  Future<void> _analyze() async {
    if (_resumeController.text.trim().isEmpty || _jdController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please paste both your resume and the job description.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _result = null;
    });

    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'API key not found. Check your .env file.';
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {'role': 'system', 'content': _systemPrompt},
            {
              'role': 'user',
              'content':
                  'Resume:\n${_resumeController.text}\n\nJob Description:\n${_jdController.text}'
            },
          ],
          'temperature': 0.3,
          'response_format': {'type': 'json_object'},
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('API error: ${response.statusCode} ${response.body}');
      }

      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'];
      final parsed = jsonDecode(content);

      setState(() {
        _result = MatchResult.fromJson(parsed);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Something went wrong: $e';
      });
    }
  }

  Widget _sectionCard({required String label, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              letterSpacing: 0.8,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Resume Matcher',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF1F2937)),
              ),
              const SizedBox(height: 4),
              const Text(
                'See how well your resume matches a job — honestly.',
                style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 24),

              _sectionCard(
                label: 'YOUR RESUME',
                child: TextField(
                  controller: _resumeController,
                  maxLines: 6,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF7F8FC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(12),
                    hintText: 'Paste your resume text here…',
                  ),
                ),
              ),
              const SizedBox(height: 16),

              _sectionCard(
                label: 'JOB DESCRIPTION',
                child: TextField(
                  controller: _jdController,
                  maxLines: 6,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF7F8FC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(12),
                    hintText: 'Paste the job description here…',
                  ),
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                height: 50,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : _analyze,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Analyze Match', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                ),
              ],

              if (_result != null) ...[
                const SizedBox(height: 24),
                _buildResultCard(_result!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String text, {required Color bg, required Color fg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(fontSize: 13, color: fg, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildResultCard(MatchResult result) {
    final scoreColor = result.matchScore >= 70
        ? const Color(0xFF16A34A)
        : result.matchScore >= 40
            ? const Color(0xFFD97706)
            : const Color(0xFFDC2626);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 96, height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scoreColor.withOpacity(0.12),
                    border: Border.all(color: scoreColor.withOpacity(0.3), width: 3),
                  ),
                  child: Center(
                    child: Text(
                      '${result.matchScore}',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: scoreColor),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'MATCH SCORE',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          Row(
            children: const [
              Icon(Icons.check_circle, size: 18, color: Color(0xFF16A34A)),
              SizedBox(width: 6),
              Text('Matched Skills', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: result.matchedSkills
                .map((s) => _chip(s, bg: const Color(0xFFE7F6EC), fg: const Color(0xFF15803D)))
                .toList(),
          ),
          const SizedBox(height: 24),

          Row(
            children: const [
              Icon(Icons.error_outline, size: 18, color: Color(0xFFDC2626)),
              SizedBox(width: 6),
              Text('Missing / Gaps', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: result.missingSkills
                .map((s) => _chip(s, bg: const Color(0xFFFCEAEA), fg: const Color(0xFFB91C1C)))
                .toList(),
          ),
          const SizedBox(height: 24),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FC),
              borderRadius: BorderRadius.circular(12),
              border: Border(left: BorderSide(color: Theme.of(context).colorScheme.primary, width: 3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Feedback', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 6),
                Text(result.feedback, style: const TextStyle(fontSize: 14, height: 1.4, color: Color(0xFF374151))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}