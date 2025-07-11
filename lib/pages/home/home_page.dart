import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dify/models/message.dart';
import 'package:flutter_dify/models/conversation.dart';
import 'package:flutter_dify/pages/home/controllers/home_controller.dart';
import 'package:flutter_dify/managers/settings_manager.dart';
import 'package:flutter_dify/widgets/conversation_drawer.dart';
import 'package:flutter_dify/pages/home/widgets/home_app_bar.dart';
import 'package:flutter_dify/pages/home/widgets/home_body.dart';
import 'package:flutter_dify/pages/home/widgets/simple_input_bar.dart';
import 'package:flutter_dify/pages/settings/settings_page.dart';
import 'package:flutter_dify/widgets/custom_title_bar.dart';
import 'package:provider/provider.dart';

// 定义系统通道，用于与原生平台通信
const platform = MethodChannel('com.han.flutter_dify/app_lifecycle');

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  late HomeController _homeController;

  @override
  void initState() {
    super.initState();
    _homeController = HomeController();
    _homeController.initialize(context, setState);
  }

  @override
  void dispose() {
    _homeController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _homeController.handleAppLifecycleChange(state);
  }

  @override
  Widget build(BuildContext context) {
    final settingsManager = Provider.of<SettingsManager>(context);
    final isApiConfigured = settingsManager.isApiConfigured;
    
    // 设置系统UI样式，让导航栏跟随应用主题
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      systemNavigationBarColor: Theme.of(context).colorScheme.surface,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: brightness,
    ));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final shouldPop = await _homeController.onWillPop();
          if (shouldPop && context.mounted) {
            // 移动端：根据设置决定是否最小化到后台，桌面端：直接退出应用
            if (Platform.isAndroid || Platform.isIOS) {
              // 移动端：根据allowBackgroundRunning设置决定行为
              if (settingsManager.allowBackgroundRunning) {
                // 允许后台运行：将应用最小化到后台
                await _homeController.minimizeToBackground();
              } else {
                // 不允许后台运行：直接退出应用
                SystemNavigator.pop();
              }
            } else {
              // 桌面端：直接退出应用
              SystemNavigator.pop();
            }
          }
        }
      },
      child: SafeArea(
        bottom: true,
        top: false,
        left: false,
        right: false,
        child: GestureDetector(
            onTap: () {
              // 点击其他地方时让输入框失焦
              FocusScope.of(context).unfocus();
              // 移动端：如果侧边栏打开，点击主界面关闭侧边栏
              // Windows端：屏幕够宽，不需要自动关闭侧边栏
              if (_homeController.isDrawerOpen && (Platform.isAndroid || Platform.isIOS)) {
                _homeController.closeDrawer();
              }
            },
            onHorizontalDragStart: (details) {
              _homeController.panStartPosition = details.globalPosition;
              _homeController.isAnimating = false;
            },
            onHorizontalDragUpdate: (details) {
              if (_homeController.panStartPosition != null) {
                final deltaX = details.globalPosition.dx - _homeController.panStartPosition!.dx;
                final baseOffset = _homeController.isDrawerOpen ? 280.0 : 0.0;
                final newOffset = (baseOffset + deltaX).clamp(0.0, 280.0);
                _homeController.updateDrawerOffset(newOffset);
              }
            },
            onHorizontalDragEnd: (details) {
              if (_homeController.panStartPosition != null) {
                final deltaX = details.globalPosition.dx - _homeController.panStartPosition!.dx;
                final velocity = details.velocity.pixelsPerSecond.dx;
                
                // 根据滑动距离和速度决定是否打开/关闭侧边栏
                if (deltaX > 140 || velocity > 500) {
                  _homeController.openDrawer();
                } else if (deltaX < -140 || velocity < -500) {
                  _homeController.closeDrawer();
                } else {
                  // 回弹到原位置
                  if (_homeController.drawerOffset > 140) {
                    _homeController.openDrawer();
                  } else {
                    _homeController.closeDrawer();
                  }
                }
              }
              _homeController.panStartPosition = null;
            },
            child: Scaffold(
              key: _homeController.scaffoldKey,
              resizeToAvoidBottomInset: true,
              body: Stack(
                children: [
                  // 主界面内容（包含AppBar）
                  Positioned.fill(
                    child: AnimatedContainer(
                      duration: _homeController.isAnimating ? const Duration(milliseconds: 250) : Duration.zero,
                      curve: Curves.easeOutCubic,
                      transform: Matrix4.translationValues(
                        _homeController.isAnimating 
                          ? (_homeController.isDrawerOpen ? 280.0 : 0.0)
                          : _homeController.drawerOffset,
                        0.0,
                        0.0,
                      ),
                      child: Container(
                      color: Theme.of(context).colorScheme.surface,
                      child: Column(
                        children: [
                          // 在Windows平台使用自定义标题栏，其他平台使用原有AppBar
                          if (Platform.isWindows)
                            CustomTitleBar(
                              title: 'DifyChat',
                              onMenuPressed: () => _homeController.toggleDrawer(),
                              showMenuButton: true,
                            )
                          else
                            HomeAppBar(
                              controller: _homeController,
                              isSelectionMode: _homeController.selectionManager.isSelectionMode,
                              selectedCount: _homeController.selectionManager.selectedCount,
                              currentConversation: _homeController.conversationManager?.currentConversation,
                            ),
                          Expanded(
                            child: HomeBody(
                              controller: _homeController,
                              isApiConfigured: isApiConfigured,
                            ),
                          ),
                          if (isApiConfigured)
                            StreamBuilder<List<Message>>(
                              stream: _homeController.messagesStreamController.stream,
                              builder: (context, snapshot) {
                                return SimpleInputBar(
                                  controller: _homeController,
                                );
                              },
                            ),
                        ],
                        ),
                      ),
                    ),
                  ),
                  // 侧边栏
                  Positioned(
                    left: 0,
                    top: 0,
                    width: 280,
                    bottom: 0,
                    child: AnimatedContainer(
                      duration: _homeController.isAnimating ? const Duration(milliseconds: 250) : Duration.zero,
                      curve: Curves.easeOutCubic,
                      transform: Matrix4.translationValues(
                        _homeController.isAnimating 
                          ? (_homeController.isDrawerOpen ? 0.0 : -280.0)
                          : _homeController.drawerOffset - 280.0,
                        0.0,
                        0.0,
                      ),
                      child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(2, 0),
                          ),
                        ],
                      ),
                      child: ConversationDrawer(
                        conversations: _homeController.conversationManager?.conversations ?? [],
                        currentId: _homeController.conversationManager?.currentConversation?.id ?? '',
                        onSelect: (conversation) {
                          _homeController.conversationManager?.switchConversation(conversation);
                          // 移动端：切换对话后关闭侧边栏
                          // Windows端：保持侧边栏打开状态
                          if (Platform.isAndroid || Platform.isIOS) {
                            _homeController.closeDrawer();
                          }
                        },
                        onDelete: (conversation) => _homeController.conversationManager?.deleteConversation(conversation),
                        onBatchDelete: (conversations) => _homeController.conversationManager?.batchDeleteConversations(conversations),
                        onRename: (conversation) => _showRenameDialog(context, conversation),
                        onNew: () {
                          _homeController.conversationManager?.newConversation();
                          // 移动端：新建对话后关闭侧边栏
                          // Windows端：保持侧边栏打开状态
                          if (Platform.isAndroid || Platform.isIOS) {
                            _homeController.closeDrawer();
                          }
                        },
                        onShowSettings: () {
                          _openSettings();
                          // 移动端：打开设置后关闭侧边栏
                          // Windows端：保持侧边栏打开状态
                          if (Platform.isAndroid || Platform.isIOS) {
                            _homeController.closeDrawer();
                          }
                        },
                        scrollController: _homeController.drawerScrollController,
                        isRefreshing: _homeController.conversationManager?.isManualRefreshing ?? false,
                        onRefresh: () async {
                          await _homeController.conversationManager?.manualRefresh();
                        },
                      ),
                    ),
                  ),
                ),

                ],
              ),
            ),
        ),
       ),
    );
  }

  void _openSettings() {
    final settingsManager = Provider.of<SettingsManager>(context, listen: false);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SettingsPage(
          settingsManager: settingsManager,
          conversationManager: _homeController.conversationManager,
          onSettingsChanged: (newSettings) async {
            // 设置更改后的处理
            await newSettings.saveToPrefs();
            // 更新缓存的设置
            SettingsManager.cachedSettings = newSettings;
            // 通知Provider更新
            settingsManager.apiBaseUrl = newSettings.apiBaseUrl;
            settingsManager.apiKey = newSettings.apiKey;
            settingsManager.userId = newSettings.userId;
            settingsManager.proxyHost = newSettings.proxyHost;
            settingsManager.proxyPort = newSettings.proxyPort;
            settingsManager.proxyUser = newSettings.proxyUser;
            settingsManager.proxyPassword = newSettings.proxyPassword;
            settingsManager.syncInterval = newSettings.syncInterval;
            settingsManager.allowBackgroundRunning = newSettings.allowBackgroundRunning;
            // 更新颜色设置（新字段）
            settingsManager.lightUserBubbleColor = newSettings.lightUserBubbleColor;
            settingsManager.lightAiBubbleColor = newSettings.lightAiBubbleColor;
            settingsManager.lightSelectedBubbleColor = newSettings.lightSelectedBubbleColor;
            settingsManager.darkUserBubbleColor = newSettings.darkUserBubbleColor;
            settingsManager.darkAiBubbleColor = newSettings.darkAiBubbleColor;
            settingsManager.darkSelectedBubbleColor = newSettings.darkSelectedBubbleColor;
            
            // 兼容性：更新旧字段（映射到浅色模式）
            settingsManager.userBubbleColor = newSettings.userBubbleColor;
            settingsManager.aiBubbleColor = newSettings.aiBubbleColor;
            settingsManager.selectedBubbleColor = newSettings.selectedBubbleColor;
            settingsManager.themeMode = newSettings.themeMode;
            settingsManager.followSystemTheme = newSettings.followSystemTheme;
            // 触发设置更新
            await settingsManager.saveToPrefs();
            
            // 重新初始化API客户端
            _homeController.reinitializeApiClients();
          },
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, Conversation conversation) {
    final TextEditingController controller = TextEditingController(text: conversation.name.isNotEmpty ? conversation.name : '新对话');
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('重命名对话'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: '请输入新的对话名称',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
            maxLength: 50,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                final newName = controller.text.trim();
                if (newName.isNotEmpty) {
                  _homeController.conversationManager?.renameConversation(conversation, newName);
                }
                Navigator.of(context).pop();
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }
}