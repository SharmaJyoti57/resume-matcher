import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'history_provider.dart';
import 'match_models.dart';
import 'result_card.dart';

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String _fmt(DateTime d) => '${_months[d.month - 1]} ${d.day}, ${d.year}';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          if (entries.isNotEmpty)
            IconButton(
              tooltip: 'Clear all',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => _confirmClear(context, ref),
            ),
        ],
      ),
      body: entries.isEmpty
          ? const _EmptyHistory()
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return Dismissible(
                      key: ValueKey(entry.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.red.withValues(alpha: 0.15),
                        child: const Icon(Icons.delete_outline, color: Colors.red),
                      ),
                      onDismissed: (_) {
                        ref.read(historyProvider.notifier).remove(entry.id);
                        ScaffoldMessenger.of(context)
                          ..clearSnackBars()
                          ..showSnackBar(
                            SnackBar(
                              content: const Text('Deleted'),
                              action: SnackBarAction(
                                label: 'Undo',
                                onPressed: () => ref.read(historyProvider.notifier).restore(entry, index),
                              ),
                            ),
                          );
                      },
                      child: _HistoryTile(entry: entry),
                    );
                  },
                ),
              ),
            ),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all history?'),
        content: const Text('This removes every saved analysis from this device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Clear')),
        ],
      ),
    );
    if (ok == true) ref.read(historyProvider.notifier).clear();
  }
}

class _HistoryTile extends ConsumerWidget {
  final HistoryEntry entry;
  const _HistoryTile({required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = verdictStyleFor(entry.result.displayVerdict);
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: style.bg,
        child: Text(
          '${entry.result.matchScore}',
          style: TextStyle(fontWeight: FontWeight.w800, color: style.fg),
        ),
      ),
      title: Text(entry.label, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${_fmt(entry.createdAt)}  ·  ${entry.result.displayVerdict}',
        style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
      ),
      trailing: PopupMenuButton<String>(
        tooltip: 'Set status',
        onSelected: (value) {
          if (value == '_rename') {
            _rename(context, ref);
          } else {
            ref.read(historyProvider.notifier).setStatus(entry.id, value);
          }
        },
        itemBuilder: (_) => [
          for (final s in kStatusLabels.entries)
            CheckedPopupMenuItem<String>(
              value: s.key,
              checked: entry.status == s.key,
              child: Text(s.value),
            ),
          const PopupMenuDivider(),
          const PopupMenuItem<String>(value: '_rename', child: Text('Rename')),
        ],
        child: Chip(
          label: Text(kStatusLabels[entry.status] ?? 'Saved', style: const TextStyle(fontSize: 12)),
          visualDensity: VisualDensity.compact,
        ),
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => _SavedResultPage(entry: entry)),
      ),
    );
  }

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    // Not disposed on purpose: disposing while the dialog's close animation
    // is still running throws. It has no listeners, so letting GC take it is fine.
    final controller = TextEditingController(text: entry.label);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Company / role'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      ref.read(historyProvider.notifier).rename(entry.id, name);
    }
  }
}

class _SavedResultPage extends StatelessWidget {
  final HistoryEntry entry;
  const _SavedResultPage({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(entry.label, maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ResultCard(result: entry.result),
          ),
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 40, color: scheme.onSurfaceVariant.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              'No analyses yet.\nEvery match you run is saved here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
