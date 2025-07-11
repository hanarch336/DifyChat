import 'dart:io';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';

class SystemTrayManager {
  final SystemTray _systemTray = SystemTray();
  final Menu _menu = Menu();
  bool _isWindowVisible = true;
  bool _isInitialized = false;
  
  // 初始化系统托盘
  Future<void> initialize() async {
    if (!Platform.isWindows) return;
    
    // 设置托盘图标
    String iconPath = Platform.isWindows ? 'assets/app_icon.ico' : 'assets/app_icon.png';
    
    try {
      // 初始化系统托盘
      await _systemTray.initSystemTray(
        title: "DifyChat",
        iconPath: iconPath,
      );
      
      // 创建系统托盘菜单
      await _menu.buildFrom([
        MenuItemLabel(label: '显示应用', onClicked: (_) => showWindow()),
        MenuItemLabel(label: '隐藏应用', onClicked: (_) => hideWindow()),
        MenuSeparator(),
        MenuItemLabel(label: '退出', onClicked: (_) => quitApp()),
      ]);
      
      // 设置系统托盘菜单
      await _systemTray.setContextMenu(_menu);
      
      // 设置托盘点击事件
      _systemTray.registerSystemTrayEventHandler((eventName) {
        // 系统托盘事件
        if (eventName == kSystemTrayEventClick) {
          if (_isWindowVisible) {
            hideWindow();
          } else {
            showWindow();
          }
        } else if (eventName == kSystemTrayEventRightClick) {
          _systemTray.popUpContextMenu();
        }
      });
      
      _isInitialized = true;
    } catch (e) {
      // 初始化系统托盘失败
    }
  }
  
  // 显示窗口
  Future<void> showWindow() async {
    if (!_isInitialized) return;
    await windowManager.show();
    await windowManager.focus();
    _isWindowVisible = true;
  }
  
  // 隐藏窗口
  Future<void> hideWindow() async {
    if (!_isInitialized) return;
    await windowManager.hide();
    _isWindowVisible = false;
  }
  
  // 最小化到托盘
  Future<void> minimizeToTray() async {
    if (!_isInitialized) return;
    await hideWindow();
    
    // 设置托盘提示
    _systemTray.setToolTip("DifyChat (后台运行中)");
    _systemTray.setTitle("DifyChat");
  }
  
  // 退出应用
  void quitApp() {
    exit(0);
  }
  
  // 释放资源
  void dispose() {
    if (!_isInitialized) return;
    
    try {
      _systemTray.destroy();
    } catch (e) {
      // 销毁系统托盘失败
    }
  }
  
  // 获取窗口可见状态
  bool get isWindowVisible => _isWindowVisible;
}