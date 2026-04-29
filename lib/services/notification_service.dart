import '../models/food_model.dart';
import 'notification_service_mobile.dart'
    if (dart.library.html) 'notification_service_stub.dart'
    as impl;

class NotificationService {
  static Future<void> init() => impl.initNotifications();
  static Future<bool> requestPermission() => impl.requestPermission();
  static Future<bool> isPermissionAllowed() => impl.isPermissionAllowed();
  static Future<void> scheduleForFood(FoodModel food) => impl.scheduleForFood(food);
  static Future<void> cancelForFood(FoodModel food) => impl.cancelForFood(food);
  static Future<void> cancelAll() => impl.cancelAll();
  static Future<void> showImmediate({
    required String title,
    required String body,
  }) => impl.showImmediate(title: title, body: body);
}