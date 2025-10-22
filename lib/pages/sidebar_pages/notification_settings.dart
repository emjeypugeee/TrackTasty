import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitness/theme/app_color.dart';
import 'package:fitness/widgets/components/my_buttons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  bool _macroTrackingEnabled = true;
  bool _weightRemindersEnabled = true;
  bool _educationalTipsEnabled = true;
  bool _progressRemindersEnabled = true;
  bool _calorieAlertsEnabled = true;

  // Meal times
  TimeOfDay _breakfastTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _lunchTime = const TimeOfDay(hour: 12, minute: 30);
  TimeOfDay _dinnerTime = const TimeOfDay(hour: 19, minute: 0);

  // Progress check time
  TimeOfDay _progressCheckTime = const TimeOfDay(hour: 19, minute: 0);

  // Weekly weight log reminder day
  int _weeklyWeightLogDay = 0; // Sunday
  TimeOfDay _weeklyWeightLogTime = const TimeOfDay(hour: 9, minute: 0);

  // Educational tips time
  TimeOfDay _educationalTipsTime = const TimeOfDay(hour: 17, minute: 0);

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
        AndroidInitializationSettings('launcher_icon');

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
      _macroTrackingEnabled = _prefs?.getBool('macroTrackingEnabled') ?? true;
      _weightRemindersEnabled =
          _prefs?.getBool('weightRemindersEnabled') ?? true;
      _educationalTipsEnabled =
          _prefs?.getBool('educationalTipsEnabled') ?? true;
      _progressRemindersEnabled =
          _prefs?.getBool('progressRemindersEnabled') ?? true;
      _calorieAlertsEnabled = _prefs?.getBool('calorieAlertsEnabled') ?? true;

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

      _progressCheckTime = TimeOfDay(
        hour: _prefs?.getInt('progressCheckTime_hour') ?? 19,
        minute: _prefs?.getInt('progressCheckTime_minute') ?? 0,
      );

      _weeklyWeightLogDay = _prefs?.getInt('weeklyWeightLogDay') ?? 0;

      _weeklyWeightLogTime = TimeOfDay(
        hour: _prefs?.getInt('weeklyWeightLogTime_hour') ?? 9,
        minute: _prefs?.getInt('weeklyWeightLogTime_minute') ?? 0,
      );

      _educationalTipsTime = TimeOfDay(
        hour: _prefs?.getInt('educationalTipsTime_hour') ?? 17,
        minute: _prefs?.getInt('educationalTipsTime_minute') ?? 0,
      );
    });
  }

  Future<void> _saveNotificationSettings() async {
    try {
      await _prefs?.setBool('notificationsEnabled', _notificationsEnabled);
      await _prefs?.setBool('mealRemindersEnabled', _mealRemindersEnabled);
      await _prefs?.setBool('macroTrackingEnabled', _macroTrackingEnabled);
      await _prefs?.setBool('weightRemindersEnabled', _weightRemindersEnabled);
      await _prefs?.setBool('educationalTipsEnabled', _educationalTipsEnabled);
      await _prefs?.setBool(
          'progressRemindersEnabled', _progressRemindersEnabled);
      await _prefs?.setBool('calorieAlertsEnabled', _calorieAlertsEnabled);

      // Save times
      await _prefs?.setInt('breakfastTime_hour', _breakfastTime.hour);
      await _prefs?.setInt('breakfastTime_minute', _breakfastTime.minute);
      await _prefs?.setInt('lunchTime_hour', _lunchTime.hour);
      await _prefs?.setInt('lunchTime_minute', _lunchTime.minute);
      await _prefs?.setInt('dinnerTime_hour', _dinnerTime.hour);
      await _prefs?.setInt('dinnerTime_minute', _dinnerTime.minute);
      await _prefs?.setInt('progressCheckTime_hour', _progressCheckTime.hour);
      await _prefs?.setInt(
          'progressCheckTime_minute', _progressCheckTime.minute);
      await _prefs?.setInt('weeklyWeightLogDay', _weeklyWeightLogDay);
      await _prefs?.setInt(
          'weeklyWeightLogTime_hour', _weeklyWeightLogTime.hour);
      await _prefs?.setInt(
          'weeklyWeightLogTime_minute', _weeklyWeightLogTime.minute);
      await _prefs?.setInt(
          'educationalTipsTime_hour', _educationalTipsTime.hour);
      await _prefs?.setInt(
          'educationalTipsTime_minute', _educationalTipsTime.minute);

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
        channelId: 'meal_reminders',
        channelName: 'Meal Reminders',
      );

      _scheduleDailyNotification(
        id: 2,
        title: 'Lunch Time! 🥗',
        body: 'What are you having for lunch? Log it to track your macros.',
        time: _lunchTime,
        channelId: 'meal_reminders',
        channelName: 'Meal Reminders',
      );

      _scheduleDailyNotification(
        id: 3,
        title: 'Dinner Time! 🍽️',
        body:
            'Complete your day by logging your dinner and reviewing your progress.',
        time: _dinnerTime,
        channelId: 'meal_reminders',
        channelName: 'Meal Reminders',
      );
    }

    // Schedule macro tracking notifications
    if (_macroTrackingEnabled) {
      _scheduleDailyNotification(
        id: 4,
        title: 'Macro Check-in 📊',
        body:
            'How are your macros looking today? Check your protein, carbs, and fats.',
        time: const TimeOfDay(hour: 16, minute: 0),
        channelId: 'macro_tracking',
        channelName: 'Macro Tracking',
      );
    }

    // Schedule progress notifications (check if user hasn't logged food today)
    if (_progressRemindersEnabled) {
      _scheduleDailyNotification(
        id: 6,
        title: 'Daily Log Reminder 📝',
        body: 'Don\'t forget to log your meals today to maintain your streak!',
        time: _progressCheckTime,
        channelId: 'progress_reminders',
        channelName: 'Progress Reminders',
      );
    }

    // Schedule educational tips
    if (_educationalTipsEnabled) {
      _scheduleDailyNotification(
        id: 7,
        title: 'Nutrition Tip 💡',
        body: _getRandomEducationalTip(),
        time: _educationalTipsTime,
        channelId: 'educational_tips',
        channelName: 'Educational Tips',
      );
    }

    // Schedule weekly weight log reminder
    if (_weightRemindersEnabled) {
      _scheduleWeeklyNotification(
        id: 8,
        title: 'Weekly Weight Log ⚖️',
        body: 'Time to log your weekly weight to track your progress!',
        day: _weeklyWeightLogDay,
        time: _weeklyWeightLogTime,
        channelId: 'weight_reminders',
        channelName: 'Weight Reminders',
      );
    }
  }

  String _getRandomEducationalTip() {
    final tips = [
      'Did you know? Protein helps build and repair tissues - aim for 1.6-2.2g per kg of body weight!',
      'Tip: Drinking water before meals can help with portion control and hydration.',
      'Healthy fats like avocados and nuts are essential for hormone production and brain health.',
      'Fiber-rich foods help with digestion and keep you feeling full longer. Aim for 25-30g daily!',
      'Complex carbs like whole grains provide sustained energy throughout the day.',
      'Meal timing: Eating protein with each meal helps maintain muscle mass and keeps you full.',
      'Hydration tip: Your body needs about 30-35ml of water per kg of body weight daily.',
      'Did you know? Sleep affects your hunger hormones - aim for 7-9 hours per night!',
    ];
    return tips[DateTime.now().day % tips.length];
  }

  Future<void> _checkAndSendProgressNotification() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('user_achievements')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final lastLoggedDate =
            userDoc.data()?['last_logged_date'] as Timestamp?;
        final today = DateTime.now();
        final todayStart = DateTime(today.year, today.month, today.day);

        if (lastLoggedDate == null ||
            lastLoggedDate.toDate().isBefore(todayStart)) {
          // User hasn't logged today
          await flutterLocalNotificationsPlugin.show(
            106,
            'Daily Log Reminder 📝',
            'You haven\'t logged any food today. Keep your streak going!',
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'progress_reminders',
                'Progress Reminders',
                channelDescription: 'Reminders to log your daily progress',
                importance: Importance.defaultImportance,
                priority: Priority.defaultPriority,
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking progress: $e');
    }
  }

  Future<void> _scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
    required String channelId,
    required String channelName,
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
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: 'Channel for $channelName',
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
    required String channelId,
    required String channelName,
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
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: 'Channel for $channelName',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> _selectTime(
      BuildContext context, bool isMealTime, int selectionType) async {
    TimeOfDay initialTime;

    switch (selectionType) {
      case 0: // Breakfast
        initialTime = _breakfastTime;
        break;
      case 1: // Lunch
        initialTime = _lunchTime;
        break;
      case 2: // Dinner
        initialTime = _dinnerTime;
        break;
      case 3: // Weekly Weight Log
        initialTime = _weeklyWeightLogTime;
        break;
      case 4: // Progress Check
        initialTime = _progressCheckTime;
        break;
      case 5: // Educational Tips
        initialTime = _educationalTipsTime;
        break;
      default:
        initialTime = const TimeOfDay(hour: 12, minute: 0);
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryColor,
              onPrimary: Colors.white,
              surface: AppColors.containerBg,
              onSurface: AppColors.primaryText,
            ),
            dialogTheme: DialogTheme(
              backgroundColor: AppColors.containerBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        switch (selectionType) {
          case 0:
            _breakfastTime = picked;
            break;
          case 1:
            _lunchTime = picked;
            break;
          case 2:
            _dinnerTime = picked;
            break;
          case 3:
            _weeklyWeightLogTime = picked;
            break;
          case 4:
            _progressCheckTime = picked;
            break;
          case 5:
            _educationalTipsTime = picked;
            break;
        }
      });
      await _saveNotificationSettings();
    }
  }

  void _selectWeeklyWeightLogDay() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.containerBg,
          title: Text(
            'Select Day for Weekly Weight Log',
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
                      _weeklyWeightLogDay = index;
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

  void _resetToDefaultTimes() {
    setState(() {
      _breakfastTime = const TimeOfDay(hour: 8, minute: 0);
      _lunchTime = const TimeOfDay(hour: 12, minute: 30);
      _dinnerTime = const TimeOfDay(hour: 19, minute: 0);
      _weeklyWeightLogTime = const TimeOfDay(hour: 9, minute: 0);
      _progressCheckTime = const TimeOfDay(hour: 19, minute: 0);
      _educationalTipsTime = const TimeOfDay(hour: 17, minute: 0);
      _weeklyWeightLogDay = 0; // Sunday
    });
    _saveNotificationSettings();
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

            const SizedBox(height: 10),

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

            // Macro Tracking
            SwitchListTile(
              activeColor: AppColors.primaryColor,
              title: Text(
                'Macro Tracking Reminders',
                style: TextStyle(color: AppColors.primaryText),
              ),
              subtitle: Text(
                'Get reminders to check your protein, carbs, and fats',
                style: TextStyle(color: AppColors.secondaryText),
              ),
              value: _macroTrackingEnabled,
              onChanged: _notificationsEnabled
                  ? (value) {
                      setState(() {
                        _macroTrackingEnabled = value;
                      });
                      _saveNotificationSettings();
                    }
                  : null,
            ),

            // Weekly Weight Log
            SwitchListTile(
              activeColor: AppColors.primaryColor,
              title: Text(
                'Weekly Weight Log Reminder',
                style: TextStyle(color: AppColors.primaryText),
              ),
              subtitle: Text(
                'Get reminded to log your weekly weight',
                style: TextStyle(color: AppColors.secondaryText),
              ),
              value: _weightRemindersEnabled,
              onChanged: _notificationsEnabled
                  ? (value) {
                      setState(() {
                        _weightRemindersEnabled = value;
                      });
                      _saveNotificationSettings();
                    }
                  : null,
            ),
            if (_weightRemindersEnabled && _notificationsEnabled) ...[
              ListTile(
                title: Text(
                  'Weekly Weight Log Day',
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
                  ][_weeklyWeightLogDay],
                  style: TextStyle(color: AppColors.primaryText),
                ),
                onTap: _selectWeeklyWeightLogDay,
              ),
              _buildTimeSetting(
                'Weekly Weight Log Time',
                _weeklyWeightLogTime,
                3,
              ),
            ],
            const Divider(),

            // Progress Notifications
            SwitchListTile(
              activeColor: AppColors.primaryColor,
              title: Text(
                'Daily Log Reminders',
                style: TextStyle(color: AppColors.primaryText),
              ),
              subtitle: Text(
                'Get notified if you haven\'t logged food today',
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
            if (_progressRemindersEnabled && _notificationsEnabled) ...[
              _buildTimeSetting(
                'Progress Check Time',
                _progressCheckTime,
                4,
              ),
            ],

            // Educational Tips
            SwitchListTile(
              activeColor: AppColors.primaryColor,
              title: Text(
                'Educational Nutrition Tips',
                style: TextStyle(color: AppColors.primaryText),
              ),
              subtitle: Text(
                'Receive helpful nutrition and fitness tips',
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
            if (_educationalTipsEnabled && _notificationsEnabled) ...[
              _buildTimeSetting(
                'Educational Tips Time',
                _educationalTipsTime,
                5,
              ),
            ],

            const Divider(),

            if (_notificationsEnabled) ...[
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: _resetToDefaultTimes,
                  child: Text(
                    'Reset to Default Times',
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSetting(String title, TimeOfDay time, int selectionType) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(color: AppColors.primaryText),
      ),
      trailing: Text(
        _formatTimeOfDay(time),
        style: TextStyle(color: AppColors.primaryText),
      ),
      onTap: () => _selectTime(context, true, selectionType),
    );
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
    final format = DateFormat.jm();
    return format.format(dt);
  }
}
