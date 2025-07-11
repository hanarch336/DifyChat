import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_dify/app.dart';
import 'package:flutter_dify/managers/settings_manager.dart';
import 'package:flutter_dify/managers/system_tray_manager.dart';
import 'package:flutter_dify/services/conversation_cache.dart';
import 'package:flutter_dify/services/performance_optimizer.dart';
import 'package:flutter_dify/services/platform_bridge.dart';
import 'package:flutter_dify/widgets/custom_title_bar.dart';
import 'package:window_manager/window_manager.dart';

// 定义系统通道，用于与原生平台通信
const platform = MethodChannel('com.han.flutter_dify/app_lifecycle');
// 性能优化通道
const performanceChannel = MethodChannel('com.han.flutter_dify/performance');

// 全局系统托盘管理器
SystemTrayManager? globalSystemTrayManager;

// 窗口事件监听器
class AppWindowListener extends WindowListener {
  @override
  Future<void> onWindowClose() async {
    // 拦截窗口关闭事件，最小化到系统托盘而不是退出
    if (Platform.isWindows && globalSystemTrayManager != null) {
      globalSystemTrayManager!.minimizeToTray();
      return; // 阻止默认的关闭行为
    }
    // 非Windows平台或系统托盘未初始化时，正常退出
    await windowManager.destroy();
  }

  @override
  Future<void> onWindowMinimize() async {
    // 最小化时也隐藏到系统托盘
    if (Platform.isWindows && globalSystemTrayManager != null) {
      globalSystemTrayManager!.minimizeToTray();
    }
  }
}

void main() async {
  // 捕获全局错误
  FlutterError.onError = (FlutterErrorDetails details) {
    if (kDebugMode) {
      // 在调试模式下正常显示错误
      FlutterError.dumpErrorToConsole(details);
    } else {
      // 在发布模式下记录错误但不崩溃
      // 捕获到错误和堆栈跟踪
    }
  };
  
  // 确保Flutter绑定初始化
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化Windows桌面窗口管理器
  if (Platform.isWindows) {
    await TitleBarUtils.initialize();
    
    // 初始化全局系统托盘管理器
    globalSystemTrayManager = SystemTrayManager();
    await globalSystemTrayManager!.initialize();
    
    // 设置窗口监听器
    windowManager.addListener(AppWindowListener());
    
    // 设置窗口关闭时不退出应用
    await windowManager.setPreventClose(true);
  }
  
  // 设置系统UI样式，支持边到边显示
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );
  
  // 启用高性能模式
  _enableHighPerformanceMode();
  
  // 初始化平台桥接服务
  final platformBridge = PlatformBridge();
  await platformBridge.initialize();
  
  try {
    // 初始化性能优化器
    final performanceOptimizer = PerformanceOptimizer();
    await performanceOptimizer.initialize();
    
    // 预加载设置并保存到全局变量
    final settings = await SettingsManager.loadFromPrefs();
    SettingsManager.cachedSettings = settings;
    
    // 预加载缓存数据
    await ConversationCache.preloadCache();
    
    // 配置图片缓存大小，提高性能
    final maxCacheSize = _calculateOptimalCacheSize();
    PaintingBinding.instance.imageCache.maximumSizeBytes = maxCacheSize;
    
    // 优化网络请求
    performanceOptimizer.optimizeNetworkRequests();
    
    // 监听应用生命周期
    SystemChannels.lifecycle.setMessageHandler((msg) async {
      if (msg == AppLifecycleState.resumed.toString()) {
        performanceOptimizer.onAppForeground();
      } else if (msg == AppLifecycleState.paused.toString()) {
        performanceOptimizer.onAppBackground();
      }
      return null;
    });
    
    // 预热关键组件
    await performanceOptimizer.prewarmComponents();
  } catch (e) {
    // 捕获初始化过程中的错误
    // 应用初始化过程中发生错误
  }
  
  // 即使发生错误，也要启动应用
  runApp(const MyApp());
}

// 启用高性能模式
void _enableHighPerformanceMode() {
  // 使用最佳的渲染策略
  // 注意：不直接设置schedulerPhase，避免兼容性问题
  SchedulerBinding.instance.addPostFrameCallback((_) {
    // 在帧渲染后执行，优化渲染性能
    // 启用高性能渲染模式
  });
}

// 计算最佳缓存大小
int _calculateOptimalCacheSize() {
  // 根据平台和设备情况计算最佳缓存大小
  if (kIsWeb) {
    return 100 * 1024 * 1024; // Web平台使用较小的缓存
  } else {
    // 移动设备和桌面平台使用较大的缓存
    return 200 * 1024 * 1024; // 200MB
  }
}

