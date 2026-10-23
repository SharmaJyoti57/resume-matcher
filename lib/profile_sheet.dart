import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'match_models.dart';
import 'profile_provider.dart';

Future<void> showProfileSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _ProfileSheet(),
  );
}

class _ProfileSheet extends ConsumerStatefulWidget {
  const _ProfileSheet();

  @override
  ConsumerState<_ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends ConsumerState<_ProfileSheet> {
  final _country = TextEditingController();
  final _location = TextEditingController();
  String _sponsorship = 'unknown'; // yes | no | unknown

  @override
  void initState() {
    super.initState();
    ref.read(profileProvider.notifier).current().then((p) {
      if (!mounted) return;
      setState(() {
        _country.text = p.country;
        _location.text = p.location;
        _sponsorship = p.needsSponsorship;
      });
    });
  }

  @override
  void dispose() {
    _country.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ref.read(profileProvider.notifier).save(
          CandidateProfile(
            country: _country.text.trim(),
            location: _location.text.trim(),
            needsSponsorship: _sponsorship,
          ),
        );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: scheme.onSurface)),
            const SizedBox(height: 6),
            Text(
              'Used only to check eligibility rules in job posts (where the job is open, sponsorship). '
              'It is never shown to the AI and never changes your score. Saved on this device.',
              style: TextStyle(fontSize: 13, height: 1.4, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _country,
              maxLength: 80,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Country you can work from',
                hintText: 'e.g. United States',
                counterText: '',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _location,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: 'City / region (optional)',
                hintText: 'e.g. Malden, MA',
                counterText: '',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Do you need visa sponsorship?',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: scheme.onSurface),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment<String>(value: 'no', label: Text('No')),
                  ButtonSegment<String>(value: 'yes', label: Text('Yes')),
                  ButtonSegment<String>(value: 'unknown', label: Text('Not set')),
                ],
                selected: {_sponsorship},
                onSelectionChanged: (s) => setState(() => _sponsorship = s.first),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: FilledButton(onPressed: _save, child: const Text('Save')),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () {
                    _country.clear();
                    _location.clear();
                    setState(() => _sponsorship = 'unknown');
                  },
                  child: const Text('Clear'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
