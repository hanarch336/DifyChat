import 'dart:async';
import 'package:flutter/material.dart';

/// 应用主题配置管理类
/// 负责管理应用在不同主题模式下的颜色配置
/// 注意：聊天气泡颜色由用户手动调整，不在此配置范围内
class AppThemeConfig {
  // 私有构造函数，防止实例化
  AppThemeConfig._();
  

  /// 获取浅色主题配置
  static ThemeData getLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: _getLightColorScheme(),
      appBarTheme: _getLightAppBarTheme(),
      scaffoldBackgroundColor: _getLightScaffoldBackground(),
      cardTheme: _getLightCardTheme(),
      elevatedButtonTheme: _getLightElevatedButtonTheme(),
      textButtonTheme: _getLightTextButtonTheme(),
      iconTheme: _getLightIconTheme(),
      dividerTheme: _getLightDividerTheme(),
      inputDecorationTheme: _getLightInputDecorationTheme(),
    );
  }

  /// 获取深色主题配置
  static ThemeData getDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: _getDarkColorScheme(),
      appBarTheme: _getDarkAppBarTheme(),
      scaffoldBackgroundColor: _getDarkScaffoldBackground(),
      cardTheme: _getDarkCardTheme(),
      elevatedButtonTheme: _getDarkElevatedButtonTheme(),
      textButtonTheme: _getDarkTextButtonTheme(),
      iconTheme: _getDarkIconTheme(),
      dividerTheme: _getDarkDividerTheme(),
      inputDecorationTheme: _getDarkInputDecorationTheme(),
    );
  }

  // ==================== 浅色主题配置 ====================

  /// 浅色主题颜色方案
  static ColorScheme _getLightColorScheme() {
    return const ColorScheme.light(
      primary: Colors.black,
      onPrimary: Colors.white,
      secondary: Colors.black54,
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: Colors.black,
      background: Colors.white,
      onBackground: Colors.black,
      error: Colors.red,
      onError: Colors.white,
    );
  }

  /// 浅色主题AppBar配置
  static AppBarTheme _getLightAppBarTheme() {
    return const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 1,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: Colors.black87,
        fontSize: 20,
        fontWeight: FontWeight.w500,
      ),
      iconTheme: IconThemeData(
        color: Colors.black87,
      ),
    );
  }

  /// 浅色主题脚手架背景色
  static Color _getLightScaffoldBackground() {
    return Colors.white;
  }

  /// 浅色主题卡片配置
  static CardThemeData _getLightCardTheme() {
    return CardThemeData(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  /// 浅色主题按钮配置
  static ElevatedButtonThemeData _getLightElevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// 浅色主题文本按钮配置
  static TextButtonThemeData _getLightTextButtonTheme() {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Colors.black,
      ),
    );
  }

  /// 浅色主题图标配置
  static IconThemeData _getLightIconTheme() {
    return const IconThemeData(
      color: Colors.black,
    );
  }

  /// 浅色主题分割线配置
  static DividerThemeData _getLightDividerTheme() {
    return const DividerThemeData(
      color: Colors.black26,
      thickness: 1,
    );
  }

  /// 浅色主题输入框配置
  static InputDecorationTheme _getLightInputDecorationTheme() {
    return InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.black26),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.black26),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.black, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  // ==================== 深色主题配置 ====================

  /// 深色主题颜色方案
  static ColorScheme _getDarkColorScheme() {
    return const ColorScheme.dark(
      primary: Colors.white,
      onPrimary: Colors.black,
      secondary: Colors.white70,
      onSecondary: Colors.black,
      surface: Colors.black,
      onSurface: Colors.white,
      background: Colors.black,
      onBackground: Colors.white,
      error: Colors.redAccent,
      onError: Colors.black,
    );
  }

  /// 深色主题AppBar配置
  static AppBarTheme _getDarkAppBarTheme() {
    return const AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      elevation: 1,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w500,
      ),
      iconTheme: IconThemeData(
        color: Colors.white,
      ),
    );
  }

  /// 深色主题脚手架背景色
  static Color _getDarkScaffoldBackground() {
    return Colors.black;
  }

  /// 深色主题卡片配置
  static CardThemeData _getDarkCardTheme() {
    return CardThemeData(
      color: Colors.black,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  /// 深色主题按钮配置
  static ElevatedButtonThemeData _getDarkElevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// 深色主题文本按钮配置
  static TextButtonThemeData _getDarkTextButtonTheme() {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
      ),
    );
  }

  /// 深色主题图标配置
  static IconThemeData _getDarkIconTheme() {
    return const IconThemeData(
      color: Colors.white,
    );
  }

  /// 深色主题分割线配置
  static DividerThemeData _getDarkDividerTheme() {
    return const DividerThemeData(
      color: Colors.white24,
      thickness: 1,
    );
  }

  /// 深色主题输入框配置
  static InputDecorationTheme _getDarkInputDecorationTheme() {
    return InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.white, width: 2),
      ),
      filled: true,
      fillColor: Colors.black,
    );
  }

  // ==================== 通用工具方法 ====================

  /// 根据亮度获取对比色
  static Color getContrastColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  /// 判断是否为深色主题
  static bool isDarkTheme(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  /// 获取当前主题的主色调
  static Color getPrimaryColor(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  /// 获取当前主题的背景色
  static Color getBackgroundColor(BuildContext context) {
    return Theme.of(context).colorScheme.background;
  }

  /// 获取当前主题的表面色
  static Color getSurfaceColor(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }

  // ==================== 性能优化工具 ====================

  static Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 300);

  /// 防抖动的主题切换方法
  /// 在短时间内多次调用时，只执行最后一次
  static void debounceThemeChange(VoidCallback callback) {
    // 取消之前的定时器
    _debounceTimer?.cancel();
    
    // 设置新的定时器
    _debounceTimer = Timer(_debounceDuration, callback);
  }

  /// 清理资源
  static void dispose() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }
}