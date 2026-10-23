import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'history_provider.dart';
import 'match_models.dart';
import 'profile_provider.dart';

// Models moved to match_models.dart; re-exported so existing imports keep working.
export 'match_models.dart';

part 'matcher_provider.g.dart';

/// Override at build time: flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
/// (10.0.2.2 is how the Android emulator reaches your computer's localhost.)
const String kApiBaseUrl =
    String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8000');

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

class _ApiError implements Exception {
  final String message;
  _ApiError(this.message);
}

String _messageForStatus(int code) {
  if (code == 400) return 'Please paste both your resume and the job description.';
  if (code == 422) return 'The server could not read that request.';
  if (code >= 500) return 'The analysis service had a problem. Please try again.';
  return 'Server error ($code). Please try again.';
}

const _genericHeadings = {
  'about the job',
  'job description',
  'about us',
  'about the role',
  'about the company',
  'overview',
  'position summary',
};

/// First meaningful line of the JD, used as the history title.
String _labelFrom(String jobDescription) {
  for (final line in jobDescription.split('\n')) {
    final t = line.trim();
    if (t.isEmpty || _genericHeadings.contains(t.toLowerCase())) continue;
    return t.length > 80 ? '${t.substring(0, 80)}…' : t;
  }
  return 'Untitled job';
}

@riverpod
class Matcher extends _$Matcher {
  @override
  MatcherState build() => const MatcherState();

  Future<void> analyze(String resume, String jobDescription) async {
    if (state.isLoading) return;

    if (resume.trim().isEmpty || jobDescription.trim().isEmpty) {
      state = state.copyWith(
        errorMessage: 'Please paste both your resume and the job description.',
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true, clearResult: true);

    try {
      // Eligibility facts (location, sponsorship) come from your saved profile, not from the resume.
      final profile = await ref.read(profileProvider.notifier).current();

      final response = await http
          .post(
            Uri.parse('$kApiBaseUrl/analyze'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'resume': resume,
              'job_description': jobDescription,
              if (!profile.isEmpty) 'profile': profile.toJson(),
            }),
          )
          .timeout(const Duration(seconds: 90));

      if (response.statusCode != 200) {
        throw _ApiError(_messageForStatus(response.statusCode));
      }

      final parsed = jsonDecode(utf8.decode(response.bodyBytes));
      if (parsed is! Map<String, dynamic>) {
        throw const FormatException('Unexpected response shape');
      }

      final result = MatchResult.fromJson(parsed);
      state = state.copyWith(isLoading: false, result: result);

      // Save to local history (fire and forget).
      unawaited(ref.read(historyProvider.notifier).add(_labelFrom(jobDescription), result));
    } on _ApiError catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } on TimeoutException {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'The analysis took too long. Please try again.',
      );
    } on http.ClientException {
      state = state.copyWith(
        isLoading: false,
        errorMessage: "Can't reach the server at $kApiBaseUrl. Is the backend running?",
      );
    } on FormatException {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'The server sent a response the app could not read.',
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Something went wrong. Please try again.',
      );
    }
  }

  void reset() {
    state = const MatcherState();
  }
}
