import 'package:flutter/material.dart';

import '../data/store.dart';
import '../services/reminder_service.dart';
import '../services/secure_backup.dart';

const _blue = Color(0xFF49B8E8);
const _mint = Color(0xFF79D6B0);
const _card = Color(0xFF102B40);

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final _name = TextEditingController();
  bool _loading = true;
  bool _remindersEnabled = false;
  bool _busy = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);
  String _fitnessLevel = 'Beginner';
  String _foodPreference = 'Flexible';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _name.text = await Store.profileName();
    _remindersEnabled = await Store.getSetting('reminder_enabled', fallback: 'false') == 'true';
    final hour = int.tryParse(await Store.getSetting('reminder_hour', fallback: '20')) ?? 20;
    final minute = int.tryParse(await Store.getSetting('reminder_minute', fallback: '0')) ?? 0;
    _reminderTime = TimeOfDay(hour: hour.clamp(0, 23), minute: minute.clamp(0, 59));
    _fitnessLevel = await Store.getSetting('fitness_level', fallback: 'Beginner');
    _foodPreference = await Store.getSetting('food_preference', fallback: 'Flexible');
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<String?> _ask(String title, {String? initial, bool? secret}) async {
    final controller = TextEditingController(text: initial ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          obscureText: secret ?? false,
          decoration: InputDecoration(hintText: secret ? 'At least 10 characters' : 'Enter details'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Continue')),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _message(String value) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  Future<void> _exportBackup() async {
    final password = await _ask('Protect your backup', secret: true);
    if (password == null) return;
    setState(() => _busy = true);
    try {
      await SecureBackup.exportToFile(password);
      await _message('Encrypted backup file created. Keep the password safe; ELORA cannot recover it.');
    } on BackupCancelled {
      // The user closed the file picker.
    } catch (error) {
      await _message('Backup could not be created: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _importBackup() async {
    final password = await _ask('Unlock your backup', secret: true);
    if (password == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Replace this device’s ELORA data?'),
        content: const Text('The selected backup will replace your habits, history, goals, meals, workouts, expenses and preferences. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Replace data')),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _busy = true);
    try {
      await SecureBackup.importFromFile(password);
      await _load();
      await _message('Your encrypted backup was restored.');
    } on BackupCancelled {
      // The user closed the file picker.
    } catch (error) {
      await _message('Restore failed. Check the password and file: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setReminder(bool enabled) async {
    if (enabled) {
      final granted = await ReminderService.instance.requestPermission();
      if (!granted) {
        await _message('Notification permission is off. Allow it in Android settings to receive reminders.');
        return;
      }
      await ReminderService.instance.scheduleDaily(hour: _reminderTime.hour, minute: _reminderTime.minute);
    } else {
      await ReminderService.instance.cancelDaily();
    }
    await Store.setSetting('reminder_enabled', enabled.toString());
    if (mounted) setState(() => _remindersEnabled = enabled);
    await _message(enabled ? 'Your daily ELORA reminder is scheduled.' : 'Daily reminders are paused.');
  }

  Future<void> _chooseReminderTime() async {
    final picked = await showTimePicker(context: context, initialTime: _reminderTime);
    if (picked == null) return;
    _reminderTime = picked;
    await Store.setSetting('reminder_hour', picked.hour.toString());
    await Store.setSetting('reminder_minute', picked.minute.toString());
    if (_remindersEnabled) {
      await ReminderService.instance.scheduleDaily(hour: picked.hour, minute: picked.minute);
    }
    if (mounted) setState(() {});
  }

  Future<void> _savePreferences() async {
    await Store.setSetting('fitness_level', _fitnessLevel);
    await Store.setSetting('food_preference', _foodPreference);
    await _message('Your preferences have been saved on this device.');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Your space', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
          const Text('Your settings, goals and personal progress stay on this device.', style: TextStyle(color: Colors.white60)),
          const SizedBox(height: 18),
          _section(
            'Your profile',
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Your name', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (_loading) const LinearProgressIndicator(),
              if (!_loading) TextField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(hintText: 'What should ELORA call you?'),
              ),
              const SizedBox(height: 10),
              FilledButton.tonal(
                onPressed: _loading ? null : () async {
                  await Store.saveProfileName(_name.text);
                  await _message('Profile saved.');
                },
                child: const Text('Save profile'),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          _section(
            'Personal preferences',
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Fitness experience'),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _fitnessLevel,
                items: const ['Beginner', 'Intermediate', 'Experienced'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                onChanged: (v) { if (v != null) setState(() => _fitnessLevel = v); },
              ),
              const SizedBox(height: 14),
              const Text('Food preference'),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _foodPreference,
                items: const ['Flexible', 'Vegetarian', 'Non-vegetarian', 'Eggetarian'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                onChanged: (v) { if (v != null) setState(() => _foodPreference = v); },
              ),
              const SizedBox(height: 10),
              FilledButton.tonal(onPressed: _savePreferences, child: const Text('Save preferences')),
            ]),
          ),
          const SizedBox(height: 12),
          _section(
            'Daily reminder',
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Gentle daily check-in'),
                subtitle: const Text('A private notification from ELORA, scheduled on this phone.'),
                value: _remindersEnabled,
                onChanged: _busy ? null : _setReminder,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule, color: _blue),
                title: const Text('Reminder time'),
                subtitle: Text(_reminderTime.format(context)),
                trailing: const Icon(Icons.chevron_right),
                onTap: _chooseReminderTime,
              ),
              const Text('Android notification permission is required. Some phone battery managers may delay background reminders.', style: TextStyle(color: Colors.white54, fontSize: 12)),
            ]),
          ),
          const SizedBox(height: 12),
          const Text('Personal goals', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _GoalsSection(ask: _ask),
          const SizedBox(height: 16),
          const Text('Your progress', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const _ProgressSection(),
          const SizedBox(height: 16),
          const Text('Your data', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(child: ListTile(
            leading: const Icon(Icons.lock_outline, color: _mint),
            title: const Text('Export encrypted backup'),
            subtitle: const Text('Create a password-protected .elora file.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _busy ? null : _exportBackup,
          )),
          Card(child: ListTile(
            leading: const Icon(Icons.file_open, color: _blue),
            title: const Text('Restore encrypted backup'),
            subtitle: const Text('Choose a .elora file and enter its password.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _busy ? null : _importBackup,
          )),
          if (_busy) const Padding(padding: EdgeInsets.all(12), child: LinearProgressIndicator()),
          const SizedBox(height: 12),
          const Text('Your backup is encrypted with AES-GCM and a password-derived key. If you lose the password, the backup cannot be unlocked. ELORA does not upload your records.', style: TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _section(String heading, Widget child) => Card(
    color: _card,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(heading, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        child,
      ]),
    ),
  );
}

class _GoalsSection extends StatefulWidget {
  const _GoalsSection({required this.ask});
  final Future<String?> Function(String, {String? initial, bool? secret}) ask;

  @override
  State<_GoalsSection> createState() => _GoalsSectionState();
}

class _GoalsSectionState extends State<_GoalsSection> {
  Future<void> _add() async {
    final title = await widget.ask('Goal name');
    if (title == null || title.trim().isEmpty) return;
    final target = await widget.ask('What does success look like?', initial: 'Make steady progress');
    await Store.addGoal(title, target ?? '');
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => Column(children: [
    Align(alignment: Alignment.centerRight, child: IconButton.filledTonal(onPressed: _add, icon: const Icon(Icons.add))),
    FutureBuilder<List<Map<String, Object?>>>(future: Store.goals(), builder: (context, snapshot) {
      if (!snapshot.hasData) return const LinearProgressIndicator();
      if (snapshot.data!.isEmpty) return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Add goals such as building a workout routine, saving money, or eating balanced meals.')));
      return Column(children: snapshot.data!.map((goal) {
        final progress = goal['progress'] as int;
        return Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(goal['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold))),
            IconButton(onPressed: () async { await Store.deleteGoal(goal['id'] as int); if (mounted) setState(() {}); }, icon: const Icon(Icons.delete_outline)),
          ]),
          Text(goal['target'] as String, style: const TextStyle(color: Colors.white60)),
          Row(children: [
            Expanded(child: Slider(value: progress.toDouble(), min: 0, max: 100, divisions: 20, label: '$progress%', onChanged: (value) async { await Store.updateGoalProgress(goal['id'] as int, value.round()); if (mounted) setState(() {}); })),
            Text('$progress%'),
          ]),
        ])));
      }).toList());
    }),
  ]);
}

class _ProgressSection extends StatelessWidget {
  const _ProgressSection();

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, Object>>(
    future: Store.progressStats(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) return const LinearProgressIndicator();
      final data = snapshot.data!;
      final labels = data['labels'] as List<String>;
      final habits = data['habits'] as List<int>;
      final expenses = data['expenses'] as List<double>;
      final workouts = data['workouts'] as List<int>;
      final maxHabit = habits.fold<int>(1, (a, b) => a > b ? a : b);
      final maxExpense = expenses.fold<double>(1, (a, b) => a > b ? a : b);
      final maxWorkout = workouts.fold<int>(1, (a, b) => a > b ? a : b);
      return Column(children: [
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Habit check-ins · last 7 days', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _Bars(values: habits.map((v) => v.toDouble()).toList(), labels: labels, maxValue: maxHabit.toDouble(), color: _mint),
        ]))),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Daily spending · last 7 days', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _Bars(values: expenses, labels: labels, maxValue: maxExpense, color: _blue, prefix: '₹'),
        ]))),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Workouts completed · last 7 days', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _Bars(values: workouts.map((v) => v.toDouble()).toList(), labels: labels, maxValue: maxWorkout.toDouble(), color: Colors.orange),
        ]))),
        Card(child: ListTile(
          leading: const Icon(Icons.flag_outlined, color: _mint),
          title: const Text('Average goal progress'),
          trailing: Text('${(data['goalAverage'] as double).round()}%', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _mint)),
        )),
      ]);
    },
  );
}

class _Bars extends StatelessWidget {
  const _Bars({required this.values, required this.labels, required this.maxValue, required this.color, this.prefix = ''});
  final List<double> values;
  final List<String> labels;
  final double maxValue;
  final Color color;
  final String prefix;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 118,
    child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: List.generate(values.length, (i) {
      final value = values[i];
      final ratio = (value / maxValue).clamp(0.0, 1.0);
      return Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
        Text(prefix.isEmpty ? value.toStringAsFixed(0) : '${prefix}${value.toStringAsFixed(0)}', style: const TextStyle(fontSize: 9, color: Colors.white60)),
        const SizedBox(height: 4),
        Container(height: 64 * ratio + 2, decoration: BoxDecoration(color: color.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(6))),
        const SizedBox(height: 5),
        Text(labels[i], style: const TextStyle(fontSize: 9, color: Colors.white60)),
      ])));
    })),
  );
}
