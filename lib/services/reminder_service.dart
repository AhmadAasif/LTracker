import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../data/store.dart';

class ReminderService {
  ReminderService._();
  static final ReminderService instance = ReminderService._();
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> initialize() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    final zoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zoneInfo.identifier));
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@drawable/elora_notification'),
    );
    await _plugin.initialize(settings: settings);
    _ready = true;
  }

  Future<bool> requestPermission() async {
    await initialize();
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    return await android?.requestNotificationsPermission() ?? false;
  }

  Future<void> scheduleDaily({required int hour, required int minute}) async {
    await initialize();
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) scheduled = scheduled.add(const Duration(days: 1));
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'elora_daily_reminder',
        'Daily ELORA reminder',
        channelDescription: 'A gentle reminder to check in with your routine.',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: 'elora_notification',
      ),
    );
    await _plugin.zonedSchedule(
      id: 4101,
      title: 'A little check-in from ELORA 🌿',
      body: 'Take a moment for your habits, wellbeing and plans today.',
      scheduledDate: scheduled,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> restoreSavedReminder() async {
    if (await Store.getSetting('reminder_enabled', fallback: 'false') != 'true') return;
    final hour = int.tryParse(await Store.getSetting('reminder_hour', fallback: '20')) ?? 20;
    final minute = int.tryParse(await Store.getSetting('reminder_minute', fallback: '0')) ?? 0;
    await scheduleDaily(hour: hour.clamp(0, 23), minute: minute.clamp(0, 59));
  }

  Future<void> cancelDaily() async {
    await initialize();
    await _plugin.cancel(id: 4101);
  }
}
