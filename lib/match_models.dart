// Models for the /analyze response, the candidate profile, and saved history.
// Every field added after v1 is optional, so an older backend response still parses.

String verdictForScore(int score) =>
    score >= 75 ? 'Apply' : (score >= 55 ? 'Stretch' : 'Skip');

List<String> _strings(dynamic v) =>
    v is List ? v.map((e) => e.toString()).toList() : <String>[];

List<T> _objects<T>(dynamic v, T Function(Map<String, dynamic>) parse) {
  if (v is! List) return <T>[];
  return [
    for (final e in v)
      if (e is Map) parse(Map<String, dynamic>.from(e)),
  ];
}

/// Facts only you know. Compared with the job post's eligibility rules by the backend's code;
/// never sent to the AI model and never used to score your resume.
class CandidateProfile {
  final String country;
  final String location; // optional city / region
  final String needsSponsorship; // yes | no | unknown

  const CandidateProfile({this.country = '', this.location = '', this.needsSponsorship = 'unknown'});

  bool get isEmpty =>
      country.trim().isEmpty && location.trim().isEmpty && needsSponsorship == 'unknown';

  Map<String, dynamic> toJson() => {
        'country': country.trim(),
        'location': location.trim(),
        'needs_sponsorship': needsSponsorship,
      };

  /// Also reads profiles saved by the older version (free-text location + work_authorization):
  /// the location is kept (the backend can read a country out of it); the free-text
  /// authorization is dropped because it could not be checked reliably.
  factory CandidateProfile.fromJson(Map<String, dynamic> j) {
    final ns = (j['needs_sponsorship'] ?? 'unknown').toString();
    return CandidateProfile(
      country: (j['country'] ?? '').toString(),
      location: (j['location'] ?? '').toString(),
      needsSponsorship: const {'yes', 'no', 'unknown'}.contains(ns) ? ns : 'unknown',
    );
  }
}

/// Eligibility condition from the JD (sponsorship, clearance, location...).
class MatchConstraint {
  final String constraint;
  final String jdQuote;
  final String status; // ok | conflict | unverifiable
  final String reason; // why, written by the backend's code (v4+)

  const MatchConstraint({
    required this.constraint,
    required this.jdQuote,
    required this.status,
    this.reason = '',
  });

  factory MatchConstraint.fromJson(Map<String, dynamic> j) => MatchConstraint(
        constraint: (j['constraint'] ?? '').toString(),
        jdQuote: (j['jd_quote'] ?? '').toString(),
        status: (j['status'] ?? 'unverifiable').toString(),
        reason: (j['reason'] ?? '').toString(),
      );
}

/// A requirement a resume cannot prove (language fluency, writing quality...). Listed, never scored.
class MatchSoftNote {
  final String requirement;
  final String jdQuote;

  const MatchSoftNote({required this.requirement, required this.jdQuote});

  factory MatchSoftNote.fromJson(Map<String, dynamic> j) => MatchSoftNote(
        requirement: (j['requirement'] ?? '').toString(),
        jdQuote: (j['jd_quote'] ?? '').toString(),
      );
}

/// One JD requirement with the resume evidence the model found for it.
class MatchRequirement {
  final String requirement;
  final String tier; // must | nice
  final bool core;
  final String status; // met | partial | missing
  final String evidence;

  const MatchRequirement({
    required this.requirement,
    required this.tier,
    required this.core,
    required this.status,
    required this.evidence,
  });

  factory MatchRequirement.fromJson(Map<String, dynamic> j) => MatchRequirement(
        requirement: (j['requirement'] ?? '').toString(),
        tier: (j['tier'] ?? 'must').toString(),
        core: j['core'] == true,
        status: (j['status'] ?? 'missing').toString(),
        evidence: (j['evidence'] ?? '').toString(),
      );
}

class MatchResult {
  final int matchScore;
  final List<String> matchedSkills;
  final List<String> missingSkills;
  final String feedback;

  // Added in v2 (all optional).
  final String verdict; // Apply | Stretch | Skip
  final List<String> partialSkills;
  final List<MatchConstraint> constraints;
  final List<MatchRequirement> requirements;
  final List<String> capsApplied;

  // Added in v3 (all optional).
  final String eligibility; // ok | check | blocked
  final List<MatchSoftNote> softRequirements;
  final bool profileUsed;

  /// The untouched response JSON, kept so history can be saved and restored.
  final Map<String, dynamic> raw;

  MatchResult({
    required this.matchScore,
    required this.matchedSkills,
    required this.missingSkills,
    required this.feedback,
    this.verdict = 'Skip',
    this.partialSkills = const [],
    this.constraints = const [],
    this.requirements = const [],
    this.capsApplied = const [],
    this.eligibility = 'ok',
    this.softRequirements = const [],
    this.profileUsed = false,
    this.raw = const {},
  });

  /// True when a JD eligibility rule conflicts with your profile.
  bool get isBlocked => eligibility == 'blocked';

  /// What the badge shows: "Blocked" overrides the fit verdict.
  String get displayVerdict => isBlocked ? 'Blocked' : verdict;

  factory MatchResult.fromJson(Map<String, dynamic> json) {
    final score = (json['match_score'] as num?)?.round() ?? 0;
    final breakdown = json['score_breakdown'] is Map
        ? Map<String, dynamic>.from(json['score_breakdown'] as Map)
        : <String, dynamic>{};
    final verdictRaw = (json['verdict'] ?? '').toString();
    const known = {'Apply', 'Stretch', 'Skip'};
    final constraints = _objects(json['hard_constraints'], MatchConstraint.fromJson);

    // Older backends have no "eligibility"; derive it from the constraints.
    var eligibility = (json['eligibility'] ?? '').toString();
    if (!const {'ok', 'check', 'blocked'}.contains(eligibility)) {
      if (constraints.any((c) => c.status == 'conflict')) {
        eligibility = 'blocked';
      } else if (constraints.any((c) => c.status == 'unverifiable')) {
        eligibility = 'check';
      } else {
        eligibility = 'ok';
      }
    }

    return MatchResult(
      matchScore: score,
      matchedSkills: _strings(json['matched_skills']),
      missingSkills: _strings(json['missing_skills']),
      feedback: (json['feedback'] ?? '').toString(),
      verdict: known.contains(verdictRaw) ? verdictRaw : verdictForScore(score),
      partialSkills: _strings(json['partial_skills']),
      constraints: constraints,
      requirements: _objects(breakdown['requirements'], MatchRequirement.fromJson),
      capsApplied: _strings(breakdown['caps_applied']),
      eligibility: eligibility,
      softRequirements: _objects(json['soft_requirements'], MatchSoftNote.fromJson),
      profileUsed: json['profile_used'] == true,
      raw: json,
    );
  }

  MatchRequirement? requirementFor(String name) {
    for (final r in requirements) {
      if (r.requirement == name) return r;
    }
    return null;
  }
}

const Map<String, String> kStatusLabels = {
  'saved': 'Saved',
  'applied': 'Applied',
  'interview': 'Interview',
  'skipped': 'Skipped',
};

class HistoryEntry {
  final String id;
  final String label;
  final DateTime createdAt;
  final String status; // key of kStatusLabels
  final MatchResult result;

  const HistoryEntry({
    required this.id,
    required this.label,
    required this.createdAt,
    required this.status,
    required this.result,
  });

  HistoryEntry copyWith({String? label, String? status}) => HistoryEntry(
        id: id,
        label: label ?? this.label,
        createdAt: createdAt,
        status: status ?? this.status,
        result: result,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'createdAt': createdAt.toIso8601String(),
        'status': status,
        'result': result.raw,
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> j) => HistoryEntry(
        id: j['id'].toString(),
        label: (j['label'] ?? 'Untitled job').toString(),
        createdAt: DateTime.tryParse((j['createdAt'] ?? '').toString()) ?? DateTime.now(),
        status: kStatusLabels.containsKey(j['status']) ? j['status'] as String : 'saved',
        result: MatchResult.fromJson(Map<String, dynamic>.from(j['result'] as Map)),
      );
}
