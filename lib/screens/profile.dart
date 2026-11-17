import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/store.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final _name = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _name.text = await Store.profileName();
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<String?> _ask(String title, {String initial = ''}) async {
    final controller = TextEditingController(text: initial);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: 'Enter details')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _backup() async {
    final value = await Store.createBackup();
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backup copied'),
        content: Text('Your ELORA backup JSON has been copied to the clipboard (${value.length} characters). Store it somewhere private. It contains your personal records.'),
        actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Done'))],
      ),
    );
  }

  Future<void> _restore() async {
    final raw = await _ask('Paste ELORA backup JSON');
    if (raw == null || raw.trim().isEmpty || !mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Replace this device’s ELORA data?'),
        content: const Text('Restoring replaces your current habits, goals, logs, budget and profile with the backup contents. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Restore')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await Store.restoreBackup(raw);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup restored successfully.')));
    } on FormatException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not restore backup: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Your space', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
          const Text('Make ELORA feel more like your companion.', style: TextStyle(color: Colors.white60)),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Your name', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (_loading) const LinearProgressIndicator(),
                if (!_loading) TextField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(hintText: 'What should ELORA call you?'),
                  onSubmitted: (_) async => Store.saveProfileName(_name.text),
                ),
                const SizedBox(height: 10),
                FilledButton.tonal(
                  onPressed: _loading ? null : () async {
                    await Store.saveProfileName(_name.text);
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved.')));
                  },
                  child: const Text('Save profile'),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Personal goals', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            IconButton.filledTonal(
              onPressed: () async {
                final title = await _ask('Goal name');
                if (title == null || title.isEmpty) return;
                final target = await _ask('What does success look like?', initial: 'Make steady progress');
                await Store.addGoal(title, target ?? '');
                if (mounted) setState(() {});
              },
              icon: const Icon(Icons.add),
            ),
          ]),
          FutureBuilder<List<Map<String, Object?>>>(
            future: Store.goals(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const LinearProgressIndicator();
              if (snapshot.data!.isEmpty) return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Add a goal such as build a workout routine, save money, or eat more balanced meals.')));
              return Column(children: snapshot.data!.map((goal) {
                final progress = goal['progress'] as int;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(goal['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold))),
                        IconButton(onPressed: () async { await Store.deleteGoal(goal['id'] as int); if (mounted) setState(() {}); }, icon: const Icon(Icons.delete_outline)),
                      ]),
                      Text(goal['target'] as String, style: const TextStyle(color: Colors.white60)),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(child: Slider(value: progress.toDouble(), min: 0, max: 100, divisions: 20, label: '$progress%', onChanged: (value) async { await Store.updateGoalProgress(goal['id'] as int, value.round()); if (mounted) setState(() {}); })),
                        Text('$progress%'),
                      ]),
                    ]),
                  ),
                );
              }).toList());
            },
          ),
          const SizedBox(height: 16),
          const Text('Your data', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Card(child: ListTile(
            leading: const Icon(Icons.backup_outlined),
            title: const Text('Copy backup'),
            subtitle: const Text('Copy your local records as JSON to keep somewhere safe.'),
            onTap: _backup,
          )),
          Card(child: ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('Restore backup'),
            subtitle: const Text('Paste a previously copied ELORA backup. Current data will be replaced.'),
            onTap: _restore,
          )),
          const SizedBox(height: 12),
          const Text('ELORA stores these records locally. A backup copied to the clipboard is not encrypted, so keep it private and clear your clipboard when finished.', style: TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }
}
