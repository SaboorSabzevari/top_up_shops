// مسیر پیشنهادی: lib/src/utils/app_navigation.dart
//
// یک navigatorKey سراسری تا سرویس‌های Toast و Loader بتوانند بدون داشتن
// BuildContext محلی (مثلاً داخل یک Repository یا Service) هم روی صفحه
// چیزی نمایش دهند. کافی است این کلید را به MaterialApp بدهید:
//   MaterialApp(navigatorKey: appNavigatorKey, ...)
import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();