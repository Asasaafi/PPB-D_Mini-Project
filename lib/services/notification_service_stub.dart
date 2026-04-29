import '../models/food_model.dart';

Future<void> initNotifications() async {}
Future<bool> requestPermission() async => false;
Future<bool> isPermissionAllowed() async => false;
Future<void> scheduleForFood(FoodModel food) async {}
Future<void> cancelForFood(FoodModel food) async {}
Future<void> cancelAll() async {}
Future<void> showImmediate({
  required String title,
  required String body,
}) async {}