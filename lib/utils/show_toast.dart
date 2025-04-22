import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:to_do/theme/styles.dart';
import 'package:toastification/toastification.dart';

enum ToastType { error, success, info }

void showToast({required String title, required ToastType type}) {
  switch (type) {
    case ToastType.info:
      toastification.show(
          title: Text(
            title,
            style: $styles.text.bodyMedium.copyWith(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          autoCloseDuration: const Duration(seconds: 5),
          icon: Icon(
            MdiIcons.informationSlabCircleOutline,
            color: Colors.white,
          ));
      break;

    case ToastType.success:
      toastification.show(
          title: Text(
            title,
            style: $styles.text.bodyMedium.copyWith(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          autoCloseDuration: const Duration(seconds: 5),
          icon: Icon(
            MdiIcons.checkCircleOutline,
            color: Colors.white,
          ));
      break;

    case ToastType.error:
      toastification.show(
          title: Text(
            title,
            style: $styles.text.bodyMedium.copyWith(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          autoCloseDuration: const Duration(seconds: 5),
          icon: Icon(
            MdiIcons.alertCircleCheckOutline,
            color: Colors.white,
          ));
      break;
  }
}
