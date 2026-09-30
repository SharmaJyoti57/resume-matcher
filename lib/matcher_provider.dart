import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'matcher_provider.g.dart';

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

// The whole screen's state as one immutable snapshot.
class MatcherState {
  final bool isLoading;
  final String? errorMessage;
  final MatchResult? result;

  const MatcherState({
    this.isLoading = false,
    this.errorMessage,
    this.result,
  });

  MatcherState copyWith({
    bool? isLoading,
    String? errorMessage,
    MatchResult? result,
    bool clearError = false,
    bool clearResult = false,
  }) {
    return MatcherState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      result: clearResult ? null : (result ?? this.result),
    );
  }
}

@riverpod
class Matcher extends _$Matcher {
  @override
  MatcherState build() => const MatcherState();

  Future<void> analyze(String resume, String jobDescription) async {
    if (resume.trim().isEmpty || jobDescription.trim().isEmpty) {
      state = state.copyWith(
        errorMessage: 'Please paste both your resume and the job description.',
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true, clearResult: true);

    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/analyze'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'resume': resume, 'job_description': jobDescription}),
      );

      if (response.statusCode != 200) {
        throw Exception('Server error: ${response.statusCode} ${response.body}');
      }

      final parsed = jsonDecode(response.body);
      state = state.copyWith(isLoading: false, result: MatchResult.fromJson(parsed));
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Something went wrong: $e');
    }
  }
  void reset() {
  state = const MatcherState();
}
}