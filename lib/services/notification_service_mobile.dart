import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import '../models/food_model.dart';
import '../core/utils/date_helper.dart';

const String _channelKey = 'food_expiry_channel';
const String _channelGroup = 'food_expiry_group';
bool _initialized = false;

Future<void> initNotifications() async {
  if (_initialized) return;
  _initialized = true;
  await AwesomeNotifications().initialize(
    null,
    [
      NotificationChannel(
        channelGroupKey: _channelGroup,
        channelKey: _channelKey,
        channelName: 'Food Expiry Reminders',
        channelDescription: 'Notifies you when food items are about to expire.',
        defaultColor: const Color(0xFF2D6A4F),
        ledColor: const Color(0xFF2D6A4F),
        importance: NotificationImportance.High,
        channelShowBadge: true,
        playSound: true,
        enableVibration: true,
      ),
    ],
    channelGroups: [
      NotificationChannelGroup(
        channelGroupKey: _channelGroup,
        channelGroupName: 'Food Expiry',
      ),
    ],
    debug: false,
  );
}

Future<bool> requestPermission() =>
    AwesomeNotifications().requestPermissionToSendNotifications();

Future<bool> isPermissionAllowed() =>
    AwesomeNotifications().isNotificationAllowed();

Future<void> scheduleForFood(FoodModel food) async {
  await initNotifications();
  final baseId = food.id.hashCode.abs() % 100000;

  final twoDaysBefore = DateHelper.twoDaysBefore(food.expiryDate);
  if (twoDaysBefore != null) {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: baseId,
        channelKey: _channelKey,
        title: 'Expiring soon: ${food.name}',
        body: '${food.name} expires in 2 days. Use it before it goes to waste!',
        notificationLayout: NotificationLayout.Default,
        category: NotificationCategory.Reminder,
      ),
      schedule: NotificationCalendar(
        year: twoDaysBefore.year,
        month: twoDaysBefore.month,
        day: twoDaysBefore.day,
        hour: 9, minute: 0, second: 0,
        preciseAlarm: true,
        allowWhileIdle: true,
      ),
    );
  }

  final onDay = DateHelper.onExpiryDay(food.expiryDate);
  if (onDay != null) {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: baseId + 1,
        channelKey: _channelKey,
        title: 'Expires today: ${food.name}',
        body: '${food.name} expires today! Check it before it goes bad.',
        notificationLayout: NotificationLayout.Default,
        category: NotificationCategory.Reminder,
      ),
      schedule: NotificationCalendar(
        year: onDay.year,
        month: onDay.month,
        day: onDay.day,
        hour: 9, minute: 0, second: 0,
        preciseAlarm: true,
        allowWhileIdle: true,
      ),
    );
  }
}

Future<void> cancelForFood(FoodModel food) async {
  final baseId = food.id.hashCode.abs() % 100000;
  await AwesomeNotifications().cancel(baseId);
  await AwesomeNotifications().cancel(baseId + 1);
}

Future<void> cancelAll() => AwesomeNotifications().cancelAll();

Future<void> showImmediate({
  required String title,
  required String body,
}) async {
  await initNotifications();
  await AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: 0,
      channelKey: _channelKey,
      title: title,
      body: body,
      notificationLayout: NotificationLayout.Default,
    ),
  );
}