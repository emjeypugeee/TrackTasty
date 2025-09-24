import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitness/theme/app_color.dart';
import 'package:fitness/widgets/components/my_buttons.dart';

class NotificationSettings extends StatefulWidget {
  const NotificationSettings({super.key});

  @override
  State<NotificationSettings> createState() => _NotificationSettingsState();
}

class _NotificationSettingsState extends State<NotificationSettings> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Notification settings state
  bool _notificationsEnabled = true;
  bool _mealRemindersEnabled = true;
  bool _goalRemindersEnabled = true;
  bool _streakRemindersEnabled = true;
  bool _weeklySummaryEnabled = true;
  bool _educationalTipsEnabled = true;
  bool _chatbotCheckinsEnabled = true;
  bool _progressRemindersEnabled = true;

  // Meal times
  TimeOfDay _breakfastTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _lunchTime = const TimeOfDay(hour: 12, minute: 30);
  TimeOfDay _dinnerTime = const TimeOfDay(hour: 19, minute: 0);

  // Weekly reminder day
  int _weeklyReminderDay = 6;
  TimeOfDay _weeklyReminderTime = const TimeOfDay(hour: 10, minute: 0);

  // SharedPreferences instance
  SharedPreferences? _prefs;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _initPreferences();
  }

  Future<void> _initPreferences() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadNotificationSettings();
    } catch (e) {
      // If SharedPreferences fails, use default values
      debugPrint("SharedPreferences error: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _initializeNotifications() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _loadNotificationSettings() async {
    setState(() {
      _notificationsEnabled = _prefs?.getBool('notificationsEnabled') ?? true;
      _mealRemindersEnabled = _prefs?.getBool('mealRemindersEnabled') ?? true;
      _goalRemindersEnabled = _prefs?.getBool('goalRemindersEnabled') ?? true;
      _streakRemindersEnabled =
          _prefs?.getBool('streakRemindersEnabled') ?? true;
      _weeklySummaryEnabled = _prefs?.getBool('weeklySummaryEnabled') ?? true;
      _educationalTipsEnabled =
          _prefs?.getBool('educationalTipsEnabled') ?? true;
      _chatbotCheckinsEnabled =
          _prefs?.getBool('chatbotCheckinsEnabled') ?? true;
      _progressRemindersEnabled =
          _prefs?.getBool('progressRemindersEnabled') ?? true;

      // Load times
      _breakfastTime = TimeOfDay(
        hour: _prefs?.getInt('breakfastTime_hour') ?? 8,
        minute: _prefs?.getInt('breakfastTime_minute') ?? 0,
      );

      _lunchTime = TimeOfDay(
        hour: _prefs?.getInt('lunchTime_hour') ?? 12,
        minute: _prefs?.getInt('lunchTime_minute') ?? 30,
      );

      _dinnerTime = TimeOfDay(
        hour: _prefs?.getInt('dinnerTime_hour') ?? 19,
        minute: _prefs?.getInt('dinnerTime_minute') ?? 0,
      );

      _weeklyReminderDay = _prefs?.getInt('weeklyReminderDay') ?? 6;

      _weeklyReminderTime = TimeOfDay(
        hour: _prefs?.getInt('weeklyReminderTime_hour') ?? 10,
        minute: _prefs?.getInt('weeklyReminderTime_minute') ?? 0,
      );
    });
  }

  Future<void> _saveNotificationSettings() async {
    try {
      await _prefs?.setBool('notificationsEnabled', _notificationsEnabled);
      await _prefs?.setBool('mealRemindersEnabled', _mealRemindersEnabled);
      await _prefs?.setBool('goalRemindersEnabled', _goalRemindersEnabled);
      await _prefs?.setBool('streakRemindersEnabled', _streakRemindersEnabled);
      await _prefs?.setBool('weeklySummaryEnabled', _weeklySummaryEnabled);
      await _prefs?.setBool('educationalTipsEnabled', _educationalTipsEnabled);
      await _prefs?.setBool('chatbotCheckinsEnabled', _chatbotCheckinsEnabled);
      await _prefs?.setBool(
          'progressRemindersEnabled', _progressRemindersEnabled);

      // Save times
      await _prefs?.setInt('breakfastTime_hour', _breakfastTime.hour);
      await _prefs?.setInt('breakfastTime_minute', _breakfastTime.minute);
      await _prefs?.setInt('lunchTime_hour', _lunchTime.hour);
      await _prefs?.setInt('lunchTime_minute', _lunchTime.minute);
      await _prefs?.setInt('dinnerTime_hour', _dinnerTime.hour);
      await _prefs?.setInt('dinnerTime_minute', _dinnerTime.minute);
      await _prefs?.setInt('weeklyReminderDay', _weeklyReminderDay);
      await _prefs?.setInt('weeklyReminderTime_hour', _weeklyReminderTime.hour);
      await _prefs?.setInt(
          'weeklyReminderTime_minute', _weeklyReminderTime.minute);

      // Schedule notifications based on new settings
      _scheduleNotifications();

      // Show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully!')),
      );
      debugPrint('Settings saved successfully!');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving settings: $e')),
      );
      debugPrint('Error saving settings: $e');
    }
  }

  Future<void> _sendTestNotification() async {
    try {
      await flutterLocalNotificationsPlugin.show(
        999,
        'Test Notification ✅',
        'Your notifications are working perfectly! This is a test notification from TrackTasty.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test_channel',
            'Test Notifications',
            channelDescription: 'Channel for testing notifications',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test notification sent!')),
      );
      debugPrint('Test notification sent successfully!');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send test notification: $e')),
      );
      debugPrint('Error sending test notification: $e');
    }
  }

  Future<void> _scheduleNotifications() async {
    // Cancel all existing notifications
    await flutterLocalNotificationsPlugin.cancelAll();

    if (!_notificationsEnabled) return;

    // Schedule meal reminders
    if (_mealRemindersEnabled) {
      _scheduleDailyNotification(
        id: 1,
        title: 'Time for Breakfast! 🍳',
        body:
            'Don\'t forget to log your breakfast to stay on track with your goals.',
        time: _breakfastTime,
      );

      _scheduleDailyNotification(
        id: 2,
        title: 'Lunch Time! 🥗',
        body: 'What are you having for lunch? Log it to track your macros.',
        time: _lunchTime,
      );

      _scheduleDailyNotification(
        id: 3,
        title: 'Dinner Time! 🍽️',
        body:
            'Complete your day by logging your dinner and reviewing your progress.',
        time: _dinnerTime,
      );
    }

    // Schedule weekly reminder
    if (_weeklySummaryEnabled) {
      _scheduleWeeklyNotification(
        id: 4,
        title: 'Weekly Progress Report',
        body:
            'Check out your weekly progress and see how you\'re doing on your goals!',
        day: _weeklyReminderDay,
        time: _weeklyReminderTime,
      );
    }

    // ADD MORE NOTIFICATION HERE IN CASE
  }

  Future<void> _scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
  }) async {
    final now = DateTime.now();
    final scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // If the time has already passed today, schedule for tomorrow
    final scheduledDateTime = scheduledTime.isBefore(now)
        ? scheduledTime.add(const Duration(days: 1))
        : scheduledTime;

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDateTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'meal_reminders',
          'Meal Reminders',
          channelDescription: 'Reminders to log your meals',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> _scheduleWeeklyNotification({
    required int id,
    required String title,
    required String body,
    required int day,
    required TimeOfDay time,
  }) async {
    final now = DateTime.now();
    final currentWeekday = now.weekday;
    int daysToAdd = (day - currentWeekday) % 7;
    if (daysToAdd < 0) daysToAdd += 7;

    final scheduledTime = DateTime(
      now.year,
      now.month,
      now.day + daysToAdd,
      time.hour,
      time.minute,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'weekly_reminders',
          'Weekly Reminders',
          channelDescription: 'Weekly progress reports and reminders',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> _selectTime(
      BuildContext context, bool isMealTime, int mealType) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isMealTime
          ? (mealType == 0
              ? _breakfastTime
              : (mealType == 1 ? _lunchTime : _dinnerTime))
          : _weeklyReminderTime,
    );

    if (picked != null) {
      setState(() {
        if (isMealTime) {
          if (mealType == 0) {
            _breakfastTime = picked;
          } else if (mealType == 1) {
            _lunchTime = picked;
          } else {
            _dinnerTime = picked;
          }
        } else {
          _weeklyReminderTime = picked;
        }
      });
      await _saveNotificationSettings();
    }
  }

  void _selectWeeklyReminderDay() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.containerBg,
          title: Text(
            'Select Day for Weekly Reminder',
            style: TextStyle(color: AppColors.primaryText),
          ),
          content: SizedBox(
            width: double.minPositive,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: 7,
              itemBuilder: (BuildContext context, int index) {
                final days = [
                  'Sunday',
                  'Monday',
                  'Tuesday',
                  'Wednesday',
                  'Thursday',
                  'Friday',
                  'Saturday'
                ];
                return ListTile(
                  title: Text(
                    days[index],
                    style: TextStyle(color: AppColors.primaryText),
                  ),
                  onTap: () {
                    setState(() {
                      _weeklyReminderDay = index;
                    });
                    Navigator.of(context).pop();
                    _saveNotificationSettings();
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Notification Settings'),
          backgroundColor: AppColors.drawerBg,
          foregroundColor: AppColors.primaryText,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: AppColors.drawerBg,
        foregroundColor: AppColors.primaryText,
      ),
      body: Container(
        color: AppColors.drawerBg,
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Master toggle
            SwitchListTile(
              activeColor: AppColors.primaryColor,
              title: Text(
                'Enable Notifications',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
                _saveNotificationSettings();
              },
            ),
            const Divider(),

            /* TEST NOTIF BUTTON
            if (_notificationsEnabled) ...[
              MyButtons(
                text: '🔔 Send Test Notification',
                onTap: _sendTestNotification,
              ),
              const SizedBox(height: 16),
              const Text(
                'Use this button to test if notifications are working:',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Divider(),
            ],*/

            // Meal Reminders Section
            Text(
              'Meal Reminders',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              activeColor: AppColors.primaryColor,
              title: Text(
                'Enable Meal Reminders',
                style: TextStyle(color: AppColors.primaryText),
              ),
              value: _mealRemindersEnabled,
              onChanged: _notificationsEnabled
                  ? (value) {
                      setState(() {
                        _mealRemindersEnabled = value;
                      });
                      _saveNotificationSettings();
                    }
                  : null,
            ),
            if (_mealRemindersEnabled && _notificationsEnabled) ...[
              _buildTimeSetting(
                'Breakfast Time',
                _breakfastTime,
                0,
              ),
              _buildTimeSetting(
                'Lunch Time',
                _lunchTime,
                1,
              ),
              _buildTimeSetting(
                'Dinner Time',
                _dinnerTime,
                2,
              ),
            ],
            const Divider(),

            // Goal Reminders
            SwitchListTile(
              activeColor: AppColors.primaryColor,
              title: Text(
                'Goal Progress Reminders',
                style: TextStyle(color: AppColors.primaryText),
              ),
              subtitle: Text(
                'Get notified when you reach milestones',
                style: TextStyle(color: AppColors.secondaryText),
              ),
              value: _goalRemindersEnabled,
              onChanged: _notificationsEnabled
                  ? (value) {
                      setState(() {
                        _goalRemindersEnabled = value;
                      });
                      _saveNotificationSettings();
                    }
                  : null,
            ),

            // Streak Reminders
            SwitchListTile(
              activeColor: AppColors.primaryColor,
              title: Text(
                'Streak Reminders',
                style: TextStyle(color: AppColors.primaryText),
              ),
              subtitle: Text(
                'Celebrate your logging streaks',
                style: TextStyle(color: AppColors.secondaryText),
              ),
              value: _streakRemindersEnabled,
              onChanged: _notificationsEnabled
                  ? (value) {
                      setState(() {
                        _streakRemindersEnabled = value;
                      });
                      _saveNotificationSettings();
                    }
                  : null,
            ),

            // Weekly Summary
            SwitchListTile(
              activeColor: AppColors.primaryColor,
              title: Text(
                'Weekly Progress Report',
                style: TextStyle(color: AppColors.primaryText),
              ),
              subtitle: Text(
                'Get a summary of your weekly progress',
                style: TextStyle(color: AppColors.secondaryText),
              ),
              value: _weeklySummaryEnabled,
              onChanged: _notificationsEnabled
                  ? (value) {
                      setState(() {
                        _weeklySummaryEnabled = value;
                      });
                      _saveNotificationSettings();
                    }
                  : null,
            ),
            if (_weeklySummaryEnabled && _notificationsEnabled) ...[
              ListTile(
                title: Text(
                  'Weekly Reminder Day',
                  style: TextStyle(color: AppColors.primaryText),
                ),
                trailing: Text(
                  [
                    'Sun',
                    'Mon',
                    'Tue',
                    'Wed',
                    'Thu',
                    'Fri',
                    'Sat'
                  ][_weeklyReminderDay],
                  style: TextStyle(color: AppColors.primaryText),
                ),
                onTap: _selectWeeklyReminderDay,
              ),
              _buildTimeSetting(
                'Weekly Reminder Time',
                _weeklyReminderTime,
                3,
                isMealTime: false,
              ),
            ],
            const Divider(),

            // Educational Tips
            SwitchListTile(
              activeColor: AppColors.primaryColor,
              title: Text(
                'Educational Tips',
                style: TextStyle(color: AppColors.primaryText),
              ),
              subtitle: Text(
                'Receive helpful nutrition tips',
                style: TextStyle(color: AppColors.secondaryText),
              ),
              value: _educationalTipsEnabled,
              onChanged: _notificationsEnabled
                  ? (value) {
                      setState(() {
                        _educationalTipsEnabled = value;
                      });
                      _saveNotificationSettings();
                    }
                  : null,
            ),

            // Progress Notifications
            SwitchListTile(
              activeColor: AppColors.primaryColor,
              title: Text(
                'Progress Notifications',
                style: TextStyle(color: AppColors.primaryText),
              ),
              subtitle: Text(
                'Get notified when you\'re behind on your goals',
                style: TextStyle(color: AppColors.secondaryText),
              ),
              value: _progressRemindersEnabled,
              onChanged: _notificationsEnabled
                  ? (value) {
                      setState(() {
                        _progressRemindersEnabled = value;
                      });
                      _saveNotificationSettings();
                    }
                  : null,
            ),

            const SizedBox(height: 20),
            /*MyButtons(
              text: 'Save Settings',
              onTap: _saveNotificationSettings,
            ),*/
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSetting(String title, TimeOfDay time, int mealType,
      {bool isMealTime = true}) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(color: AppColors.primaryText),
      ),
      trailing: Text(
        _formatTimeOfDay(time),
        style: TextStyle(color: AppColors.primaryText),
      ),
      onTap: () => _selectTime(context, isMealTime, mealType),
    );
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
    final format = DateFormat.jm();
    return format.format(dt);
  }
}
