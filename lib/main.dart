import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
//localization
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ui_design/constant/app_url.dart';
import 'package:ui_design/constant/constant_key.dart';
import 'package:ui_design/data_provider/pref_helper.dart';
import 'package:ui_design/module/login_page/constants.dart';
import 'package:ui_design/module/login_page/views/screen_name.dart';
import 'package:ui_design/utils/app_version.dart';
import 'package:ui_design/utils/enum.dart';
import 'package:ui_design/utils/navigation.dart';
import 'package:ui_design/utils/network_connection.dart';
import 'package:ui_design/utils/styles/k_colors.dart';
import 'package:google_fonts/google_fonts.dart';

import 'module/login_page/views/welcome_page/welcome_screen.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Auth',
        theme: ThemeData(
          primaryColor: kPrimaryColor,
          scaffoldBackgroundColor: Colors.white,
        ),
        home: const WelcomeScreen());
  }
}
