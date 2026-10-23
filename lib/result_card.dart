import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'match_models.dart';
import 'score_gauge.dart';

// ---------- Verdict styling (shared with the history page) ----------

class VerdictStyle {
  final Color bg;
  final Color fg;
  final IconData icon;
  final String blurb;

  const VerdictStyle({
    required this.bg,
    required this.fg,
    required this.icon,
    required this.blurb,
  });
}

VerdictStyle verdictStyleFor(String verdict) {
  switch (verdict) {
    case 'Apply':
      return const VerdictStyle(
        bg: Color(0xFFE7F6EC),
        fg: Color(0xFF15803D),
        icon: Icons.check_circle,
        blurb: 'Strong match. Worth applying.',
      );
    case 'Stretch':
      return const VerdictStyle(
        bg: Color(0xFFFFF4DB),
        fg: Color(0xFF92600A),
        icon: Icons.trending_up,
        blurb: 'Partial match. Apply if you can close or explain the gaps.',
      );
    case 'Blocked':
      return const VerdictStyle(
        bg: Color(0xFFFCEAEA),
        fg: Color(0xFFB91C1C),
        icon: Icons.block,
        blurb: 'You match the role, but an eligibility rule conflicts with your profile.',
      );
    default:
      return const VerdictStyle(
        bg: Color(0xFFFCEAEA),
        fg: Color(0xFFB91C1C),
        icon: Icons.block,
        blurb: 'Major gaps. Low odds for this one.',
      );
  }
}

// ---------- The result card ----------

class ResultCard extends StatelessWidget {
  final MatchResult result;
  const ResultCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final capsText = result.capsApplied.join(', ');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BlockersBanner(constraints: result.constraints, profileUsed: result.profileUsed),
          Center(child: ScoreGauge(score: result.matchScore)),
          const SizedBox(height: 16),
          Center(child: _VerdictBadge(verdict: result.displayVerdict)),
          if (result.capsApplied.isNotEmpty) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Score capped: $capsText',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            'Tap a skill to see the evidence from your resume.',
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          _SkillGroup(
            title: 'Matched Skills',
            icon: Icons.check_circle,
            iconColor: const Color(0xFF16A34A),
            skills: result.matchedSkills,
            bg: const Color(0xFFE7F6EC),
            fg: const Color(0xFF15803D),
            status: 'met',
            result: result,
          ),
          _SkillGroup(
            title: 'Partial Match',
            icon: Icons.timelapse,
            iconColor: const Color(0xFFD97706),
            skills: result.partialSkills,
            bg: const Color(0xFFFFF4DB),
            fg: const Color(0xFF92600A),
            status: 'partial',
            result: result,
          ),
          _SkillGroup(
            title: 'Missing / Gaps',
            icon: Icons.error_outline,
            iconColor: const Color(0xFFDC2626),
            skills: result.missingSkills,
            bg: const Color(0xFFFCEAEA),
            fg: const Color(0xFFB91C1C),
            status: 'missing',
            result: result,
          ),
          _NotScoredSection(notes: result.softRequirements),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border(left: BorderSide(color: scheme.primary, width: 3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Feedback', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: scheme.onSurface)),
                const SizedBox(height: 6),
                Text(result.feedback, style: TextStyle(fontSize: 14, height: 1.4, color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _copySummary(context),
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy summary'),
            ),
          ),
        ],
      ),
    );
  }

  String _summaryText() {
    final b = StringBuffer('${result.displayVerdict} - ${result.matchScore}/100\n');
    void section(String title, List<String> items) {
      if (items.isEmpty) return;
      b.writeln('\n$title:');
      for (final s in items) {
        b.writeln('- $s');
      }
    }

    section('Matched', result.matchedSkills);
    section('Partial', result.partialSkills);
    section('Missing', result.missingSkills);
    section('Not scored', [for (final s in result.softRequirements) s.requirement]);
    b.writeln('\nFeedback: ${result.feedback}');
    return b.toString().trim();
  }

  Future<void> _copySummary(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _summaryText()));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(content: Text('Summary copied')));
  }
}

// ---------- Verdict badge ----------

class _VerdictBadge extends StatelessWidget {
  final String verdict;
  const _VerdictBadge({required this.verdict});

  @override
  Widget build(BuildContext context) {
    final style = verdictStyleFor(verdict);
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: style.bg, borderRadius: BorderRadius.circular(24)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(style.icon, size: 18, color: style.fg),
              const SizedBox(width: 8),
              Text(verdict, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: style.fg)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          style.blurb,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

// ---------- Blockers (sponsorship, clearance, location...) ----------

class _BlockersBanner extends StatelessWidget {
  final List<MatchConstraint> constraints;
  final bool profileUsed;
  const _BlockersBanner({required this.constraints, required this.profileUsed});

  @override
  Widget build(BuildContext context) {
    final items = constraints.where((c) => c.status != 'ok' && c.constraint.isNotEmpty).toList();
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          for (final c in items) _blockerTile(c),
        ],
      ),
    );
  }

  Widget _blockerTile(MatchConstraint c) {
    final isConflict = c.status == 'conflict';
    final bg = isConflict ? const Color(0xFFFCEAEA) : const Color(0xFFFFF4DB);
    final fg = isConflict ? const Color(0xFFB91C1C) : const Color(0xFF92600A);
    final prefix = isConflict ? 'Blocker' : 'Check before applying';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(isConflict ? Icons.block : Icons.help_outline, size: 18, color: fg),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$prefix: ${c.constraint}', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: fg)),
                if (c.jdQuote.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(c.jdQuote, style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: fg.withValues(alpha: 0.85))),
                ],
                if (c.reason.isNotEmpty || !isConflict) ...[
                  const SizedBox(height: 6),
                  Text(
                    c.reason.isNotEmpty
                        ? c.reason
                        : (profileUsed
                            ? "Your profile doesn't cover this one."
                            : 'Add your country in Profile (top right) to check this automatically.'),
                    style: TextStyle(fontSize: 12, color: fg.withValues(alpha: 0.85)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Requirements a resume can't prove (listed, never scored) ----------

class _NotScoredSection extends StatelessWidget {
  final List<MatchSoftNote> notes;
  const _NotScoredSection({required this.notes});

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.remove_circle_outline, size: 18, color: scheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                'Not scored (${notes.length})',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: scheme.onSurface),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "A resume can't prove these, so they don't affect your score.",
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final n in notes)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: Text(n.requirement, style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------- Skill chips ----------

class _SkillGroup extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<String> skills;
  final Color bg;
  final Color fg;
  final String status; // met | partial | missing
  final MatchResult result;

  const _SkillGroup({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.skills,
    required this.bg,
    required this.fg,
    required this.status,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    if (skills.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 6),
              Text(
                '$title (${skills.length})',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: scheme.onSurface),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in skills)
                _SkillChip(
                  text: s,
                  bg: bg,
                  fg: fg,
                  onTap: () => showEvidenceSheet(context, result, s, status),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;

  const _SkillChip({required this.text, required this.bg, required this.fg, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);
    return Material(
      color: bg,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(text, style: TextStyle(fontSize: 13, color: fg, fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }
}

// ---------- Evidence bottom sheet ----------

const Map<String, String> _statusWord = {
  'met': 'Matched',
  'partial': 'Partial',
  'missing': 'Missing',
};

void showEvidenceSheet(BuildContext context, MatchResult result, String name, String status) {
  final req = result.requirementFor(name);
  final scheme = Theme.of(context).colorScheme;
  final evidence = (req?.evidence ?? '').trim();

  final tags = <String>[
    _statusWord[status] ?? status,
    if (req != null) (req.tier == 'nice' ? 'Nice to have' : 'Must have'),
    if (req != null && req.core) 'Core requirement',
  ];

  String body;
  if (evidence.isNotEmpty) {
    body = evidence;
  } else if (status == 'missing') {
    body = 'Nothing in your resume was found for this requirement. '
        'If you do have this experience, add it to your resume so it can be matched.';
  } else {
    body = 'No quote is available for this requirement.';
  }

  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: scheme.onSurface)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final t in tags)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: Text(t, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'EVIDENCE FROM YOUR RESUME',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
                border: Border(left: BorderSide(color: scheme.primary, width: 3)),
              ),
              child: Text(
                body,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  fontStyle: evidence.isNotEmpty ? FontStyle.italic : FontStyle.normal,
                  color: scheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
