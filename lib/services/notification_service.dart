import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/task.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  static const String _channelId = 'task_reminders';
  static const String _channelName = 'Task Reminders';
  static const String _channelDescription = 'Notifications for task reminders and updates';

  // Initialize notifications
  Future<void> initialize() async {
    try {
      // Initialize local notifications
      await _initializeLocalNotifications();
      
      // Request permission for notifications
      final NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted permission for notifications');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('User granted provisional permission for notifications');
      } else {
        debugPrint('User declined or has not accepted permission for notifications');
      }

      // Get the token
      final String? token = await getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');
        // TODO: Send token to your server
      }

      // Set up foreground message handler
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

      // Handle notification taps when app is in background or terminated
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check if app was opened from a terminated state via notification
      final RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }
  
  // Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
    
    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
    );
    
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }
  
  // Handle notification tap
  void _onNotificationTap(NotificationResponse notificationResponse) {
    debugPrint('Notification tapped: ${notificationResponse.payload}');
    // Handle navigation based on payload
  }

  // Schedule task reminder (1 hour before due date)
  Future<void> scheduleTaskReminder(Task task) async {
    if (task.dueDate == null) return;
    
    final reminderTime = task.dueDate!.subtract(const Duration(hours: 1));
    final now = DateTime.now();
    
    // Only schedule if reminder time is in the future
    if (reminderTime.isBefore(now)) return;
    
    // Create notification details with dynamic content
    final bigTextContent = '⏰ Don\'t forget! "${task.title}" is due in 1 hour. Tap to view details.';
    
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(
        bigTextContent,
        htmlFormatBigText: true,
        contentTitle: '⏰ Task Reminder',
        htmlFormatContentTitle: true,
        summaryText: 'TaskManager',
        htmlFormatSummaryText: true,
      ),
      color: const Color(0xFFFF9800),
      enableVibration: true,
      playSound: true,
      actions: const [
        AndroidNotificationAction(
          'mark_complete',
          '✅ Mark Complete',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'view_task',
          '👁️ View Task',
          showsUserInterface: true,
        ),
      ],
    );
    
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      subtitle: '⏰ Due in 1 hour',
    );
    
    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _localNotifications.zonedSchedule(
      task.id.hashCode, // Use task ID hash as notification ID
      '⏰ Task Reminder',
      '📅 "${task.title}" is due in 1 hour',
      _convertToTZDateTime(reminderTime),
      notificationDetails,
      payload: 'task_reminder:${task.id}',
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
    
    debugPrint('Scheduled reminder for task "${task.title}" at $reminderTime');
  }
  
  // Cancel task reminder
  Future<void> cancelTaskReminder(String taskId) async {
    await _localNotifications.cancel(taskId.hashCode);
    debugPrint('Cancelled reminder for task: $taskId');
  }
  
  // Show task completion notification
  Future<void> showTaskCompletionNotification(Task task) async {
    // Create notification details with dynamic content
    final bigTextContent = '🎉 Great job! You\'ve completed "${task.title}". Keep up the momentum!';
    
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(
        bigTextContent,
        htmlFormatBigText: true,
        contentTitle: '✅ Task Completed!',
        htmlFormatContentTitle: true,
        summaryText: 'TaskManager',
        htmlFormatSummaryText: true,
      ),
      color: const Color(0xFF4CAF50),
      enableVibration: true,
      playSound: true,
    );
    
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
      subtitle: '🎉 Great job!',
    );
    
    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _localNotifications.show(
      task.id.hashCode + 1000, // Different ID for completion notifications
      '✅ Task Completed!',
      '🎉 "${task.title}" has been completed successfully!',
      notificationDetails,
      payload: 'task_completed:${task.id}',
    );
  }
  
  // Helper method to convert DateTime to TZDateTime
  tz.TZDateTime _convertToTZDateTime(DateTime dateTime) {
    // Using local timezone
    final location = tz.local;
    return tz.TZDateTime.from(dateTime, location);
  }
  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  // Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic $topic: $e');
    }
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic $topic: $e');
    }
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Received foreground message: ${message.messageId}');
    debugPrint('Title: ${message.notification?.title}');
    debugPrint('Body: ${message.notification?.body}');
    debugPrint('Data: ${message.data}');

    // Show local notification or update UI
    _showLocalNotification(message);
  }

  // Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('Notification tapped: ${message.messageId}');
    debugPrint('Data: ${message.data}');

    // Navigate to specific screen based on notification data
    _handleNotificationNavigation(message.data);
  }

  // Show local notification (you might want to use flutter_local_notifications for this)
  void _showLocalNotification(RemoteMessage message) {
    // Implementation depends on your local notification setup
    // For now, just print the message
    debugPrint('Showing local notification: ${message.notification?.title}');
  }

  // Handle notification navigation
  void _handleNotificationNavigation(Map<String, dynamic> data) {
    final String? type = data['type'];
    final String? taskId = data['taskId'];

    switch (type) {
      case 'task_reminder':
        // Navigate to task details
        debugPrint('Navigate to task: $taskId');
        break;
      case 'task_overdue':
        // Navigate to overdue tasks
        debugPrint('Navigate to overdue tasks');
        break;
      default:
        // Navigate to home
        debugPrint('Navigate to home');
    }
  }

  // Delete FCM token (for logout)
  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      debugPrint('FCM token deleted');
    } catch (e) {
      debugPrint('Error deleting FCM token: $e');
    }
  }
}

// Top-level function for background message handling
@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  debugPrint('Received background message: ${message.messageId}');
  debugPrint('Title: ${message.notification?.title}');
  debugPrint('Body: ${message.notification?.body}');
  debugPrint('Data: ${message.data}');
}