import 'package:flutter/material.dart';
import 'package:flutter_dify/pages/home/home_page.dart';
import 'package:flutter_dify/managers/settings_manager.dart';
import 'package:flutter_dify/themes/app_theme_config.dart';
import 'package:provider/provider.dart';

// 全局保持一个SettingsManager实例
final globalSettingsManager = SettingsManager();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 使用同步方法获取设置，因为我们已经在main函数中预加载了设置
    return FutureBuilder<SettingsManager>(
      // 使用已经加载的设置，减少等待时间
      future: Future.microtask(() => SettingsManager.loadFromPrefs()),
      builder: (context, snapshot) {
        // 如果设置还没加载完成，显示加载界面
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }
        
        final settingsManager = snapshot.data ?? SettingsManager();
        
        // 使用全局变量保存设置管理器
        SettingsManager.cachedSettings = settingsManager;
        
        return ChangeNotifierProvider<SettingsManager>.value(
          value: settingsManager,
          child: Consumer<SettingsManager>(
            builder: (context, settings, child) {
              return MaterialApp(
                title: 'DifyChat',
                theme: AppThemeConfig.getLightTheme(),
                darkTheme: AppThemeConfig.getDarkTheme(),
                themeMode: settings.followSystemTheme ? ThemeMode.system : settings.themeMode,
                home: const MyHomePage(title: 'DifyChat'),
              );
            },
          ),
        );
      },
    );
  }
}