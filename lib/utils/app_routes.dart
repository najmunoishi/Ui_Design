import 'package:flutter/material.dart';
import 'package:ui_design/module/login_page/views/screen_name.dart';

enum AppRoutes {
  dashboard,
}

extension AppRoutesExtention on AppRoutes {
  Widget buildWidget<T extends Object>({T? arguments}) {
    switch (this) {
      case AppRoutes.dashboard:
        return DashboardScreen();
    }
  }
}
