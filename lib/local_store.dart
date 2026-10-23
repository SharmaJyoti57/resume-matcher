import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'match_models.dart';

/// Tiny wrapper over SharedPreferences. Every call swallows storage errors
/// (private browsing, blocked storage, corrupt data) so the app still works without it.
class LocalStore {
  static const _resumeKey = 'resume_v1';
  static const _historyKey = 'history_v1';
  static const _profileKey = 'profile_v1';

  static Future<String> loadResume() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_resumeKey) ?? '';
    } catch (_) {
      return '';
    }
  }

  static Future<void> saveResume(String text) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_resumeKey, text);
    } catch (_) {}
  }

  static Future<CandidateProfile> loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_profileKey);
      if (raw == null || raw.isEmpty) return const CandidateProfile();
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const CandidateProfile();
      return CandidateProfile.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return const CandidateProfile();
    }
  }

  static Future<void> saveProfile(CandidateProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
    } catch (_) {}
  }

  static Future<List<HistoryEntry>> loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_historyKey);
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      final out = <HistoryEntry>[];
      for (final item in decoded) {
        try {
          out.add(HistoryEntry.fromJson(Map<String, dynamic>.from(item as Map)));
        } catch (_) {
          // Skip a corrupt entry instead of losing the whole history.
        }
      }
      return out;
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveHistory(List<HistoryEntry> entries) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _historyKey,
        jsonEncode(entries.map((e) => e.toJson()).toList()),
      );
    } catch (_) {}
  }
}
