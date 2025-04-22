import 'dart:developer';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationController extends GetxController {
  static NotificationController get to => Get.find();
  final isLoadingAuth = true.obs;

  @override
  void onInit() {
    super.onInit();
    checkNotificationPermission();
  }

  Future<void> checkNotificationPermission() async {
    PermissionStatus status = await Permission.notification.request();

    if (status.isGranted) {
      log("permission granted");
    } else if (status.isDenied) {
      log("permission denied");
    } else if (status.isPermanentlyDenied) {
      log("permission permanently denied");
    } else if (status.isRestricted) {
      log("permission restricted");
    } else if (status.isLimited) {
      log("permission limited");
    } else if (status.isProvisional) {
      log("permission provisional");
    }
  }
}
