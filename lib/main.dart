import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'matcher_provider.dart';
import 'theme.dart';
import 'score_gauge.dart';


final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

void main() {
  runApp(const ProviderScope(child: ResumeMatcherApp()));
}

class ResumeMatcherApp extends ConsumerWidget {
  const ResumeMatcherApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'Resume Matcher',
      debugShowCheckedModeBanner: false,
      themeMode: mode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: const MatcherHomePage(),
    );
  }
}

class MatcherHomePage extends ConsumerStatefulWidget {
  const MatcherHomePage({super.key});

  @override
  ConsumerState<MatcherHomePage> createState() => _MatcherHomePageState();
}

class _MatcherHomePageState extends ConsumerState<MatcherHomePage> {
  final _resumeController = TextEditingController();
  final _jdController = TextEditingController();

  @override
  void dispose() {
    _resumeController.dispose();
    _jdController.dispose();
    super.dispose();
  }

  void _handleAnalyze() {
    ref.read(matcherProvider.notifier).analyze(
          _resumeController.text,
          _jdController.text,
        );
  }

  void _handleReset() {
    _resumeController.clear();
    _jdController.clear();
    ref.read(matcherProvider.notifier).reset();
  }

  @override
  Widget build(BuildContext context) {
    final matcherState = ref.watch(matcherProvider);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 900;
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 48 : 20,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(),
                    const SizedBox(height: 28),
                    if (isWide)
                      _WideLayout(
                        resumeController: _resumeController,
                        jdController: _jdController,
                        matcherState: matcherState,
                        onAnalyze: _handleAnalyze,
                        onReset: _handleReset,
                      )
                    else
                      _NarrowLayout(
                        resumeController: _resumeController,
                        jdController: _jdController,
                        matcherState: matcherState,
                        onAnalyze: _handleAnalyze,
                        onReset: _handleReset,
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ---------- Header ----------

class _Header extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Resume Matcher',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: scheme.onSurface),
              ),
              Text(
                'See how well your resume matches a job — honestly.',
                style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Toggle theme',
          onPressed: () {
            final current = ref.read(themeModeProvider);
            final isCurrentlyDark = current == ThemeMode.dark ||
                (current == ThemeMode.system && brightness == Brightness.dark);
            ref.read(themeModeProvider.notifier).state =
                isCurrentlyDark ? ThemeMode.light : ThemeMode.dark;
          },
          icon: Icon(brightness == Brightness.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
        ),
      ],
    );
  }
}

// ---------- Shared input card ----------

class _InputCard extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final int maxLines;

  const _InputCard({
    required this.label,
    required this.controller,
    required this.hint,
    this.maxLines = 8,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 0.8,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              // Live character count — cheap to compute, reacts without
              // rebuilding the whole card via ListenableBuilder.
              ListenableBuilder(
                listenable: controller,
                builder: (context, _) => Text(
                  '${controller.text.length} chars',
                  style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant.withValues(alpha: 0.7)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              filled: true,
              fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(12),
              hintText: hint,
              suffixIcon: ListenableBuilder(
                listenable: controller,
                builder: (context, _) => controller.text.isEmpty
                    ? const SizedBox.shrink()
                    : IconButton(
                        tooltip: 'Clear',
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: controller.clear,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Narrow (mobile) layout ----------

class _NarrowLayout extends StatelessWidget {
  final TextEditingController resumeController;
  final TextEditingController jdController;
  final MatcherState matcherState;
  final VoidCallback onAnalyze;
  final VoidCallback onReset;

  const _NarrowLayout({
    required this.resumeController,
    required this.jdController,
    required this.matcherState,
    required this.onAnalyze,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InputCard(label: 'YOUR RESUME', controller: resumeController, hint: 'Paste your resume text here…'),
        const SizedBox(height: 16),
        _InputCard(label: 'JOB DESCRIPTION', controller: jdController, hint: 'Paste the job description here…'),
        const SizedBox(height: 20),
        _ActionRow(matcherState: matcherState, onAnalyze: onAnalyze, onReset: onReset),
        const SizedBox(height: 20),
        _ResultArea(matcherState: matcherState, minHeight: 260),
      ],
    );
  }
}

// ---------- Wide (web/desktop) layout: inputs left, results pinned right ----------

class _WideLayout extends StatelessWidget {
  final TextEditingController resumeController;
  final TextEditingController jdController;
  final MatcherState matcherState;
  final VoidCallback onAnalyze;
  final VoidCallback onReset;

  const _WideLayout({
    required this.resumeController,
    required this.jdController,
    required this.matcherState,
    required this.onAnalyze,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _InputCard(label: 'YOUR RESUME', controller: resumeController, hint: 'Paste your resume text here…', maxLines: 10),
              const SizedBox(height: 16),
              _InputCard(label: 'JOB DESCRIPTION', controller: jdController, hint: 'Paste the job description here…', maxLines: 10),
              const SizedBox(height: 20),
              _ActionRow(matcherState: matcherState, onAnalyze: onAnalyze, onReset: onReset),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 4,
          child: _ResultArea(matcherState: matcherState, minHeight: 520),
        ),
      ],
    );
  }
}

// ---------- Analyze / Reset buttons ----------

class _ActionRow extends StatelessWidget {
  final MatcherState matcherState;
  final VoidCallback onAnalyze;
  final VoidCallback onReset;

  const _ActionRow({required this.matcherState, required this.onAnalyze, required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 50,
            child: FilledButton(
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: matcherState.isLoading ? null : onAnalyze,
              child: matcherState.isLoading
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Analyze Match', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
        if (matcherState.result != null) ...[
          const SizedBox(width: 12),
          SizedBox(
            height: 50,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: onReset,
              child: const Text('Analyze another'),
            ),
          ),
        ],
      ],
    );
  }
}

// ---------- Results area: empty state / skeleton / animated result ----------

class _ResultArea extends StatelessWidget {
  final MatcherState matcherState;
  final double minHeight;

  const _ResultArea({required this.matcherState, required this.minHeight});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(animation),
            child: child,
          ),
        ),
        child: _buildChild(context),
      ),
    );
  }

  Widget _buildChild(BuildContext context) {
    if (matcherState.errorMessage != null) {
      return _ErrorCard(key: const ValueKey('error'), message: matcherState.errorMessage!);
    }
    if (matcherState.isLoading) {
      return const _SkeletonCard(key: ValueKey('loading'));
    }
    if (matcherState.result != null) {
      return _ResultCard(key: ValueKey('result-${matcherState.result!.matchScore}'), result: matcherState.result!);
    }
    return const _EmptyState(key: ValueKey('empty'));
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor, style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insights_outlined, size: 40, color: scheme.onSurfaceVariant.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(
            'Paste a resume and a job description,\nthen hit Analyze to see how they match.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}

/// Simple built-in shimmer — no extra package. A looping opacity pulse
/// on placeholder bars, shown while a request is in flight.
class _SkeletonCard extends StatefulWidget {
  const _SkeletonCard({super.key});

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: FadeTransition(
        opacity: Tween(begin: 0.35, end: 0.85).animate(_controller),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 96, height: 96,
                decoration: BoxDecoration(shape: BoxShape.circle, color: scheme.surfaceContainerHighest),
              ),
            ),
            const SizedBox(height: 28),
            _bar(scheme, width: 140),
            const SizedBox(height: 14),
            _bar(scheme, width: double.infinity),
            const SizedBox(height: 8),
            _bar(scheme, width: double.infinity),
            const SizedBox(height: 24),
            _bar(scheme, width: 120),
            const SizedBox(height: 14),
            _bar(scheme, width: double.infinity, height: 60),
          ],
        ),
      ),
    );
  }

  Widget _bar(ColorScheme scheme, {required double width, double height = 14}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final MatchResult result;
  const _ResultCard({super.key, required this.result});

  Widget _chip(BuildContext context, String text, {required Color bg, required Color fg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(fontSize: 13, color: fg, fontWeight: FontWeight.w500)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
          Center(child: ScoreGauge(score: result.matchScore)),
          const SizedBox(height: 28),

          Row(
            children: [
              const Icon(Icons.check_circle, size: 18, color: Color(0xFF16A34A)),
              const SizedBox(width: 6),
              Text('Matched Skills', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: scheme.onSurface)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: result.matchedSkills
                .map((s) => _chip(context, s, bg: const Color(0xFFE7F6EC), fg: const Color(0xFF15803D)))
                .toList(),
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              const Icon(Icons.error_outline, size: 18, color: Color(0xFFDC2626)),
              const SizedBox(width: 6),
              Text('Missing / Gaps', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: scheme.onSurface)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: result.missingSkills
                .map((s) => _chip(context, s, bg: const Color(0xFFFCEAEA), fg: const Color(0xFFB91C1C)))
                .toList(),
          ),
          const SizedBox(height: 24),

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
        ],
      ),
    );
  }
}