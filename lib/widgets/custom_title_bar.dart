import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_dify/main.dart' show globalSystemTrayManager;

/// 自定义标题栏组件，用于Windows桌面应用
/// 提供现代化的窗口控制按钮和拖拽功能
class CustomTitleBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Widget? leading;
  final List<Widget>? actions;
  final double height;
  final bool showWindowControls;
  final bool showMenuButton;
  final VoidCallback? onMenuPressed;

  const CustomTitleBar({
    Key? key,
    required this.title,
    this.backgroundColor,
    this.foregroundColor,
    this.leading,
    this.actions,
    this.height = 48.0,
    this.showWindowControls = true,
    this.showMenuButton = false,
    this.onMenuPressed,
  }) : super(key: key);

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  State<CustomTitleBar> createState() => _CustomTitleBarState();
}

class _CustomTitleBarState extends State<CustomTitleBar> with WindowListener {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    if (Platform.isWindows) {
      windowManager.addListener(this);
      _checkMaximized();
    }
  }

  @override
  void dispose() {
    if (Platform.isWindows) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  Future<void> _checkMaximized() async {
    final isMaximized = await windowManager.isMaximized();
    if (mounted) {
      setState(() {
        _isMaximized = isMaximized;
      });
    }
  }

  @override
  void onWindowMaximize() {
    setState(() {
      _isMaximized = true;
    });
  }

  @override
  void onWindowUnmaximize() {
    setState(() {
      _isMaximized = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = widget.backgroundColor ?? theme.appBarTheme.backgroundColor ?? theme.primaryColor;
    final foregroundColor = widget.foregroundColor ?? theme.appBarTheme.foregroundColor ?? theme.primaryTextTheme.titleLarge?.color ?? Colors.white;

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, 1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          // Leading widget
          if (widget.leading != null) widget.leading!,
          
          // 菜单按钮
          if (widget.showMenuButton)
            _WindowControlButton(
              icon: Icons.menu,
              onPressed: widget.onMenuPressed ?? () {},
              foregroundColor: foregroundColor,
            ),
          
          // 可拖拽区域
          Expanded(
            child: DragToMoveArea(
              child: Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  widget.title,
                  style: TextStyle(
                    color: foregroundColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          
          // Actions
          if (widget.actions != null) ...widget.actions!,
          
          // Windows控制按钮
          if (Platform.isWindows && widget.showWindowControls) ..._buildWindowControls(foregroundColor),
        ],
      ),
    );
  }

  List<Widget> _buildWindowControls(Color foregroundColor) {
    return [
      _WindowControlButton(
        icon: Icons.remove,
        onPressed: () => windowManager.minimize(),
        foregroundColor: foregroundColor,
      ),
      _WindowControlButton(
        icon: _isMaximized ? Icons.fullscreen_exit : Icons.fullscreen,
        onPressed: () async {
          if (_isMaximized) {
            await windowManager.unmaximize();
          } else {
            await windowManager.maximize();
          }
        },
        foregroundColor: foregroundColor,
      ),
      _WindowControlButton(
        icon: Icons.close,
        onPressed: () async {
          // 在Windows上最小化到系统托盘，而不是直接关闭
          if (Platform.isWindows && globalSystemTrayManager != null) {
            await globalSystemTrayManager!.minimizeToTray();
          } else {
            await windowManager.close();
          }
        },
        foregroundColor: foregroundColor,
        isCloseButton: true,
      ),
    ];
  }
}

/// 窗口控制按钮组件
class _WindowControlButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color foregroundColor;
  final bool isCloseButton;

  const _WindowControlButton({
    required this.icon,
    required this.onPressed,
    required this.foregroundColor,
    this.isCloseButton = false,
  });

  @override
  State<_WindowControlButton> createState() => _WindowControlButtonState();
}

class _WindowControlButtonState extends State<_WindowControlButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          width: 46,
          height: 32,
          decoration: BoxDecoration(
            color: _isHovered
                ? (widget.isCloseButton ? Colors.red : Colors.grey.withOpacity(0.2))
                : Colors.transparent,
          ),
          child: Icon(
            widget.icon,
            size: 16,
            color: _isHovered && widget.isCloseButton
                ? Colors.white
                : widget.foregroundColor,
          ),
        ),
      ),
    );
  }
}

/// 标题栏工具类
class TitleBarUtils {
  /// 初始化窗口管理器
  static Future<void> initialize() async {
    if (!Platform.isWindows) return;
    
    await windowManager.ensureInitialized();
    
    const windowOptions = WindowOptions(
      size: Size(1200, 800),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden, // 隐藏系统标题栏
    );
    
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
  
  /// 设置窗口标题
  static Future<void> setTitle(String title) async {
    if (!Platform.isWindows) return;
    await windowManager.setTitle(title);
  }
  
  /// 设置窗口大小
  static Future<void> setSize(Size size) async {
    if (!Platform.isWindows) return;
    await windowManager.setSize(size);
  }
  
  /// 居中窗口
  static Future<void> center() async {
    if (!Platform.isWindows) return;
    await windowManager.center();
  }
}