import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dify/models/conversation.dart';
import 'package:flutter_dify/models/message.dart';
import 'package:flutter_dify/managers/conversation_manager.dart';
import 'package:flutter_dify/pages/settings/settings_page.dart';
import 'package:flutter_dify/services/conversation_api.dart';
import 'package:flutter_dify/services/proxy_client.dart';
import 'package:flutter_dify/widgets/color_picker.dart';

class SettingsManager extends ChangeNotifier {
  // 静态缓存，用于加速配置加载
  static SettingsManager? cachedSettings;
  
  // 应用设置状态
  String apiBaseUrl;
  String apiKey;
  String userId;
  String? proxyHost;
  int? proxyPort;
  String? proxyUser;
  String? proxyPassword;
  int syncInterval;
  bool allowBackgroundRunning;
  
  // 气泡颜色设置 - 浅色模式
  Color lightUserBubbleColor;
  Color lightAiBubbleColor;
  Color lightSelectedBubbleColor;
  
  // 气泡颜色设置 - 深色模式
  Color darkUserBubbleColor;
  Color darkAiBubbleColor;
  Color darkSelectedBubbleColor;
  
  // 兼容性属性（已废弃，保留用于迁移）
  @Deprecated('使用 lightUserBubbleColor 或 darkUserBubbleColor')
  Color get userBubbleColor => lightUserBubbleColor;
  @Deprecated('使用 lightAiBubbleColor 或 darkAiBubbleColor')
  Color get aiBubbleColor => lightAiBubbleColor;
  @Deprecated('使用 lightSelectedBubbleColor 或 darkSelectedBubbleColor')
  Color get selectedBubbleColor => lightSelectedBubbleColor;
  
  set userBubbleColor(Color color) => lightUserBubbleColor = color;
  set aiBubbleColor(Color color) => lightAiBubbleColor = color;
  set selectedBubbleColor(Color color) => lightSelectedBubbleColor = color;
  
  // 主题设置
  ThemeMode themeMode;
  bool followSystemTheme;
  
  // 当前对话ID（用于记住上次打开的对话）
  String? currentConversationId;
  
  // 构造函数
  SettingsManager({
    this.apiBaseUrl = 'https://api.dify.ai/v1',
    this.apiKey = '',
    this.userId = '',
    this.proxyHost,
    this.proxyPort,
    this.proxyUser,
    this.proxyPassword,
    this.syncInterval = 3,
    this.allowBackgroundRunning = true,
    // 浅色模式默认颜色
    this.lightUserBubbleColor = const Color(0xFFE3F2FD), // 浅蓝色
    this.lightAiBubbleColor = const Color(0xFFF5F5F5),   // 浅灰色
    this.lightSelectedBubbleColor = const Color(0xFFBBDEFB), // 中蓝色
    // 深色模式默认颜色
    this.darkUserBubbleColor = const Color(0xFF1E3A8A),  // 深蓝色
    this.darkAiBubbleColor = const Color(0xFF374151),    // 深灰色
    this.darkSelectedBubbleColor = const Color(0xFF3B82F6), // 亮蓝色
    this.themeMode = ThemeMode.system, // 默认跟随系统主题
    this.followSystemTheme = true, // 默认跟随系统主题
    this.currentConversationId, // 当前对话ID
  });
  
  // 从SharedPreferences加载设置
  static Future<SettingsManager> loadFromPrefs() async {
    // 如果已有缓存，直接返回缓存
    if (cachedSettings != null) {
      return cachedSettings!;
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 尝试加载颜色值，如果失败则使用默认值
      Color lightUserBubbleColor, lightAiBubbleColor, lightSelectedBubbleColor;
      Color darkUserBubbleColor, darkAiBubbleColor, darkSelectedBubbleColor;
      
      try {
        // 默认颜色值常量
        const defaultLightUserColor = 0xFFE3F2FD;
        const defaultLightAiColor = 0xFFF5F5F5;
        const defaultLightSelectedColor = 0xFFBBDEFB;
        const defaultDarkUserColor = 0xFF1E3A8A;
        const defaultDarkAiColor = 0xFF374151;
        const defaultDarkSelectedColor = 0xFF3B82F6;
        
        // 加载浅色模式颜色
        final lightUserColorValue = prefs.getInt('lightUserBubbleColor');
        final lightAiColorValue = prefs.getInt('lightAiBubbleColor');
        final lightSelectedColorValue = prefs.getInt('lightSelectedBubbleColor');
        
        // 加载深色模式颜色
        final darkUserColorValue = prefs.getInt('darkUserBubbleColor');
        final darkAiColorValue = prefs.getInt('darkAiBubbleColor');
        final darkSelectedColorValue = prefs.getInt('darkSelectedBubbleColor');
        
        // 兼容性处理：如果新字段不存在，尝试从旧字段迁移
        final legacyUserColorValue = prefs.getInt('userBubbleColor');
        final legacyAiColorValue = prefs.getInt('aiBubbleColor');
        final legacySelectedColorValue = prefs.getInt('selectedBubbleColor');
        
        // 设置浅色模式颜色（优先使用新字段，否则使用旧字段或默认值）
        lightUserBubbleColor = lightUserColorValue != null 
            ? Color(lightUserColorValue) 
            : (legacyUserColorValue != null ? Color(legacyUserColorValue) : const Color(defaultLightUserColor));
        lightAiBubbleColor = lightAiColorValue != null 
            ? Color(lightAiColorValue) 
            : (legacyAiColorValue != null ? Color(legacyAiColorValue) : const Color(defaultLightAiColor));
        lightSelectedBubbleColor = lightSelectedColorValue != null 
            ? Color(lightSelectedColorValue) 
            : (legacySelectedColorValue != null ? Color(legacySelectedColorValue) : const Color(defaultLightSelectedColor));
        
        // 设置深色模式颜色（使用新字段或默认值）
        darkUserBubbleColor = darkUserColorValue != null ? Color(darkUserColorValue) : const Color(defaultDarkUserColor);
        darkAiBubbleColor = darkAiColorValue != null ? Color(darkAiColorValue) : const Color(defaultDarkAiColor);
        darkSelectedBubbleColor = darkSelectedColorValue != null ? Color(darkSelectedColorValue) : const Color(defaultDarkSelectedColor);
      } catch (e) {
        // 加载颜色值失败，使用默认颜色
        lightUserBubbleColor = const Color(0xFFE3F2FD);
        lightAiBubbleColor = const Color(0xFFF5F5F5);
        lightSelectedBubbleColor = const Color(0xFFBBDEFB);
        darkUserBubbleColor = const Color(0xFF1E3A8A);
        darkAiBubbleColor = const Color(0xFF374151);
        darkSelectedBubbleColor = const Color(0xFF3B82F6);
      }
      
      // 加载主题设置
      final themeModeIndex = prefs.getInt('themeMode') ?? ThemeMode.system.index;
      final followSystemTheme = prefs.getBool('followSystemTheme') ?? true;
      
      cachedSettings = SettingsManager(
        apiBaseUrl: prefs.getString('apiBaseUrl') ?? 'https://api.dify.ai/v1',
        apiKey: prefs.getString('apiKey') ?? '',
        userId: prefs.getString('userId') ?? '',
        proxyHost: prefs.getString('proxyHost'),
        proxyPort: prefs.getInt('proxyPort'),
        proxyUser: prefs.getString('proxyUser'),
        proxyPassword: prefs.getString('proxyPassword'),
        syncInterval: prefs.getInt('syncInterval') ?? 3,
        allowBackgroundRunning: prefs.getBool('allowBackgroundRunning') ?? true,
        lightUserBubbleColor: lightUserBubbleColor,
        lightAiBubbleColor: lightAiBubbleColor,
        lightSelectedBubbleColor: lightSelectedBubbleColor,
        darkUserBubbleColor: darkUserBubbleColor,
        darkAiBubbleColor: darkAiBubbleColor,
        darkSelectedBubbleColor: darkSelectedBubbleColor,
        themeMode: ThemeMode.values[themeModeIndex],
        followSystemTheme: followSystemTheme,
        currentConversationId: prefs.getString('currentConversationId'),
      );
      
      return cachedSettings!;
    } catch (e) {
      // 加载设置失败，使用默认设置
      
      // 如果加载设置失败，返回默认设置
      cachedSettings = SettingsManager();
      return cachedSettings!;
    }
  }
  
  // 获取当前对话ID的静态方法
  static Future<String?> getCurrentConversationId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('currentConversationId');
    } catch (e) {
      return null;
    }
  }
  
  // 批量更新设置，减少UI重建次数
  void updateSettings({
    String? apiBaseUrl,
    String? apiKey,
    String? userId,
    String? proxyHost,
    int? proxyPort,
    String? proxyUser,
    String? proxyPassword,
    int? syncInterval,
    bool? allowBackgroundRunning,
    Color? userBubbleColor, // 已废弃，保留兼容性
    Color? aiBubbleColor,   // 已废弃，保留兼容性
    Color? selectedBubbleColor, // 已废弃，保留兼容性
    Color? lightUserBubbleColor,
    Color? lightAiBubbleColor,
    Color? lightSelectedBubbleColor,
    Color? darkUserBubbleColor,
    Color? darkAiBubbleColor,
    Color? darkSelectedBubbleColor,
    ThemeMode? themeMode,
    bool? followSystemTheme,
    String? currentConversationId,
  }) {
    bool hasChanges = false;
    
    if (apiBaseUrl != null && this.apiBaseUrl != apiBaseUrl) {
      this.apiBaseUrl = apiBaseUrl;
      hasChanges = true;
    }
    if (apiKey != null && this.apiKey != apiKey) {
      this.apiKey = apiKey;
      hasChanges = true;
    }
    if (userId != null && this.userId != userId) {
      this.userId = userId;
      hasChanges = true;
    }
    if (proxyHost != this.proxyHost) {
      this.proxyHost = proxyHost;
      hasChanges = true;
    }
    if (proxyPort != this.proxyPort) {
      this.proxyPort = proxyPort;
      hasChanges = true;
    }
    if (proxyUser != this.proxyUser) {
      this.proxyUser = proxyUser;
      hasChanges = true;
    }
    if (proxyPassword != this.proxyPassword) {
      this.proxyPassword = proxyPassword;
      hasChanges = true;
    }
    if (syncInterval != null && this.syncInterval != syncInterval) {
      this.syncInterval = syncInterval;
      hasChanges = true;
    }
    if (allowBackgroundRunning != null && this.allowBackgroundRunning != allowBackgroundRunning) {
      this.allowBackgroundRunning = allowBackgroundRunning;
      hasChanges = true;
    }
    // 兼容性处理：旧的颜色参数映射到浅色模式
    if (userBubbleColor != null && this.lightUserBubbleColor != userBubbleColor) {
      this.lightUserBubbleColor = userBubbleColor;
      hasChanges = true;
    }
    if (aiBubbleColor != null && this.lightAiBubbleColor != aiBubbleColor) {
      this.lightAiBubbleColor = aiBubbleColor;
      hasChanges = true;
    }
    if (selectedBubbleColor != null && this.lightSelectedBubbleColor != selectedBubbleColor) {
      this.lightSelectedBubbleColor = selectedBubbleColor;
      hasChanges = true;
    }
    
    // 新的颜色参数处理
    if (lightUserBubbleColor != null && this.lightUserBubbleColor != lightUserBubbleColor) {
      this.lightUserBubbleColor = lightUserBubbleColor;
      hasChanges = true;
    }
    if (lightAiBubbleColor != null && this.lightAiBubbleColor != lightAiBubbleColor) {
      this.lightAiBubbleColor = lightAiBubbleColor;
      hasChanges = true;
    }
    if (lightSelectedBubbleColor != null && this.lightSelectedBubbleColor != lightSelectedBubbleColor) {
      this.lightSelectedBubbleColor = lightSelectedBubbleColor;
      hasChanges = true;
    }
    if (darkUserBubbleColor != null && this.darkUserBubbleColor != darkUserBubbleColor) {
      this.darkUserBubbleColor = darkUserBubbleColor;
      hasChanges = true;
    }
    if (darkAiBubbleColor != null && this.darkAiBubbleColor != darkAiBubbleColor) {
      this.darkAiBubbleColor = darkAiBubbleColor;
      hasChanges = true;
    }
    if (darkSelectedBubbleColor != null && this.darkSelectedBubbleColor != darkSelectedBubbleColor) {
      this.darkSelectedBubbleColor = darkSelectedBubbleColor;
      hasChanges = true;
    }
    if (themeMode != null && this.themeMode != themeMode) {
      this.themeMode = themeMode;
      hasChanges = true;
    }
    if (followSystemTheme != null && this.followSystemTheme != followSystemTheme) {
      this.followSystemTheme = followSystemTheme;
      hasChanges = true;
    }
    if (currentConversationId != this.currentConversationId) {
      this.currentConversationId = currentConversationId;
      hasChanges = true;
    }
    
    // 只有在有实际变化时才通知监听器
    if (hasChanges) {
      notifyListeners();
    }
  }

  // 保存设置到SharedPreferences
  Future<void> saveToPrefs() async {
    try {
      // 开始保存设置到SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      
      // 使用单独的try-catch块保存每个设置，确保即使某个设置保存失败，其他设置仍然能保存
      try {
        await prefs.setString('apiBaseUrl', apiBaseUrl);
        // 保存apiBaseUrl成功
    } catch (e) {
      // 保存apiBaseUrl失败
      }
      
      try {
        await prefs.setString('apiKey', apiKey);
        // 保存apiKey成功
    } catch (e) {
      // 保存apiKey失败
      }
      
      try {
        await prefs.setString('userId', userId);
        // 保存userId成功
    } catch (e) {
      // 保存userId失败
      }
      
      try {
        if (proxyHost != null && proxyHost!.isNotEmpty) {
          await prefs.setString('proxyHost', proxyHost!);
        } else {
          await prefs.remove('proxyHost');
        }
        // 保存proxyHost成功
      } catch (e) {
        // 保存proxyHost失败
      }
      
      try {
        if (proxyPort != null) {
          await prefs.setInt('proxyPort', proxyPort!);
        } else {
          await prefs.remove('proxyPort');
        }
        // 保存proxyPort成功
      } catch (e) {
        // 保存proxyPort失败
      }
      
      try {
        if (proxyUser != null && proxyUser!.isNotEmpty) {
          await prefs.setString('proxyUser', proxyUser!);
        } else {
          await prefs.remove('proxyUser');
        }
        // 保存proxyUser成功
      } catch (e) {
        // 保存proxyUser失败
      }
      
      try {
        if (proxyPassword != null && proxyPassword!.isNotEmpty) {
          await prefs.setString('proxyPassword', proxyPassword!);
        } else {
          await prefs.remove('proxyPassword');
        }
        // 保存proxyPassword成功
      } catch (e) {
        // 保存proxyPassword失败
      }
      
      try {
        await prefs.setInt('syncInterval', syncInterval);
        // 保存syncInterval成功
    } catch (e) {
      // 保存syncInterval失败
      }
      
      try {
        await prefs.setBool('allowBackgroundRunning', allowBackgroundRunning);
        // 保存allowBackgroundRunning成功
    } catch (e) {
      // 保存allowBackgroundRunning失败
      }
      
      // 保存气泡颜色设置
      try {
        // 先记录颜色值，便于调试
        // 保存颜色值
        
        // 保存浅色模式颜色
        await prefs.setInt('lightUserBubbleColor', lightUserBubbleColor.value);
        await prefs.setInt('lightAiBubbleColor', lightAiBubbleColor.value);
        await prefs.setInt('lightSelectedBubbleColor', lightSelectedBubbleColor.value);
        
        // 保存深色模式颜色
        await prefs.setInt('darkUserBubbleColor', darkUserBubbleColor.value);
        await prefs.setInt('darkAiBubbleColor', darkAiBubbleColor.value);
        await prefs.setInt('darkSelectedBubbleColor', darkSelectedBubbleColor.value);
        
        // 兼容性：保存旧的颜色字段（映射到浅色模式）
        await prefs.setInt('userBubbleColor', lightUserBubbleColor.value);
        await prefs.setInt('aiBubbleColor', lightAiBubbleColor.value);
        await prefs.setInt('selectedBubbleColor', lightSelectedBubbleColor.value);
        
        // 保存气泡颜色成功
      } catch (e) {
        // 如果保存颜色值失败，尝试使用默认颜色
        // 保存颜色值失败，使用默认颜色
        try {
          // 使用固定的颜色值常量
          const defaultUserColor = 0xFFE3F2FD;
          const defaultAiColor = 0xFFF5F5F5;
          const defaultSelectedColor = 0xFFBBDEFB;
          
          await prefs.setInt('userBubbleColor', defaultUserColor);
          await prefs.setInt('aiBubbleColor', defaultAiColor);
          await prefs.setInt('selectedBubbleColor', defaultSelectedColor);
          
          // 更新当前实例的颜色值为默认值
          userBubbleColor = const Color(defaultUserColor);
          aiBubbleColor = const Color(defaultAiColor);
          selectedBubbleColor = const Color(defaultSelectedColor);
        } catch (innerE) {
          // 保存默认颜色值也失败
        }
      }
      
      // 保存主题设置
      try {
        await prefs.setInt('themeMode', themeMode.index);
        await prefs.setBool('followSystemTheme', followSystemTheme);
        // 保存主题设置成功
    } catch (e) {
      // 保存主题设置失败
      }
      
      // 保存同步间隔
      try {
        await prefs.setInt('syncInterval', syncInterval);
        // 保存同步间隔成功
      } catch (e) {
        // 保存同步间隔失败
      }
      
      // 保存允许后台运行设置
      try {
        await prefs.setBool('allowBackgroundRunning', allowBackgroundRunning);
        // 保存允许后台运行设置成功
      } catch (e) {
        // 保存允许后台运行设置失败
      }
      
      // 保存当前对话ID
      try {
        if (currentConversationId != null && currentConversationId!.isNotEmpty) {
          await prefs.setString('currentConversationId', currentConversationId!);
        } else {
          await prefs.remove('currentConversationId');
        }
        // 保存当前对话ID成功
      } catch (e) {
        // 保存当前对话ID失败
      }
      
      // 更新缓存
      cachedSettings = this;
      
      // 保存设置完成
    } catch (e) {
      // 捕获并记录错误，防止应用崩溃
      // 保存设置到SharedPreferences时出错
      // 重新抛出异常，让调用者可以处理
      rethrow;
    }
  }
  
  // 预加载设置，在应用启动时调用
  static Future<void> preloadSettings() async {
    if (cachedSettings == null) {
      await loadFromPrefs();
    }
  }
  
  // 创建API客户端
  ConversationApi createApiClient() {
    final client = (proxyHost != null && proxyPort != null)
        ? ProxyHttpClient(
            proxyHost: proxyHost!,
            proxyPort: proxyPort!,
            proxyUser: proxyUser,
            proxyPassword: proxyPassword)
        : http.Client();
    
    return ConversationApi(
      baseUrl: apiBaseUrl,
      apiKey: apiKey,
      userId: userId,
      client: client,
    );
  }
  
  // 检查API是否已配置
  bool get isApiConfigured => apiKey.isNotEmpty && userId.isNotEmpty;
  
  // 测试连接性
  Future<String?> testConnectivity({
    String? testApiBaseUrl,
    String? testApiKey,
    String? testUserId,
    String? testProxyHost,
    String? testProxyPort,
    String? testProxyUser,
    String? testProxyPassword,
  }) async {
    final currentApiBaseUrl = testApiBaseUrl ?? apiBaseUrl;
    final currentApiKey = testApiKey ?? apiKey;
    final currentUserId = testUserId ?? userId;
    final currentProxyHost = testProxyHost ?? proxyHost;
    final currentProxyPort = testProxyPort ?? proxyPort?.toString();
    final currentProxyUser = testProxyUser ?? proxyUser;
    final currentProxyPassword = testProxyPassword ?? proxyPassword;

    if (currentApiBaseUrl.isEmpty || currentApiKey.isEmpty || currentUserId.isEmpty) {
      return '请完整填写API Base URL、API Key和User ID。';
    }

    http.Client client;
    if (currentProxyHost != null && currentProxyPort != null && currentProxyHost.isNotEmpty && currentProxyPort.isNotEmpty) {
      final parsedPort = int.tryParse(currentProxyPort);
      if (parsedPort == null) return '代理端口格式不正确。';
      client = ProxyHttpClient(
        proxyHost: currentProxyHost,
        proxyPort: parsedPort,
        proxyUser: currentProxyUser,
        proxyPassword: currentProxyPassword,
      );
    } else {
      client = http.Client();
    }

    try {
      final testConversationApi = ConversationApi(
        baseUrl: currentApiBaseUrl,
        apiKey: currentApiKey.trim(),
        userId: currentUserId.trim(),
        client: client,
      );
      await testConversationApi.fetchConversations().timeout(const Duration(seconds: 15));
      return null;
    } on SocketException catch (e) {
      return '网络连接失败或代理不可达: ${e.message}';
    } on TimeoutException {
      return '连接或请求超时，请检查网络和代理速度。';
    } on HandshakeException catch (e) {
      return 'SSL/TLS 握手失败，可能是证书问题或代理协议不兼容: ${e.message}';
    } on FormatException catch (e) {
      return 'API Base URL或代理端口格式错误: ${e.message}';
    } on http.ClientException catch (e) {
      return 'HTTP 客户端错误: ${e.message}';
    } on Exception catch (e) {
      if (e.toString().contains('401')) {
        return 'API 认证失败 (401 Unauthorized)。请检查API Key或User ID是否正确。';
      } else if (e.toString().contains('400')) {
        return 'API 请求错误 (400 Bad Request)。请检查API Base URL、API Key和User ID。';
      }
      return '未知错误: $e';
    } finally {
      client.close();
    }
  }
  
  // 显示设置对话框或页面（根据平台）
  static Future<SettingsManager?> showSettingsDialog(BuildContext context, SettingsManager currentSettings, {Function(SettingsManager)? onSettingsUpdated, ConversationManager? conversationManager}) async {
    // 判断是否为移动平台
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    
    if (isMobile) {
      // 在移动端显示完整页面
      return Navigator.of(context).push<SettingsManager>(
        MaterialPageRoute(
          builder: (context) => SettingsPage(
            settingsManager: currentSettings,
            conversationManager: conversationManager ?? ConversationManager(
               conversationApi: ConversationApi(
                 baseUrl: currentSettings.apiBaseUrl,
                 apiKey: currentSettings.apiKey,
                 userId: currentSettings.userId,
               ),
               messagesStreamController: StreamController<List<Message>>.broadcast(),
               showTopSnackBar: (message, {isError = false}) {},
             ),
            onSettingsChanged: (updatedSettings) async {
              // 不自动返回聊天界面，只更新设置
              // 用户需要手动点击返回按钮返回聊天界面
              await updatedSettings.saveToPrefs();
              if (onSettingsUpdated != null) {
                onSettingsUpdated(updatedSettings);
              }
            },
          ),
        ),
      );
    } else {
      // 在PC端显示弹窗
      return _showSettingsDialogDesktop(context, currentSettings);
    }
  }
  
  // 在PC端显示设置弹窗
  static Future<SettingsManager?> _showSettingsDialogDesktop(BuildContext context, SettingsManager currentSettings) async {
    final apiBaseUrlController = TextEditingController(text: currentSettings.apiBaseUrl);
    final apiKeyController = TextEditingController(text: currentSettings.apiKey);
    final userIdController = TextEditingController(text: currentSettings.userId);
    final proxyHostController = TextEditingController(text: currentSettings.proxyHost ?? '');
    final proxyPortController = TextEditingController(text: currentSettings.proxyPort?.toString() ?? '');
    final proxyUserController = TextEditingController(text: currentSettings.proxyUser ?? '');
    final proxyPasswordController = TextEditingController(text: currentSettings.proxyPassword ?? '');
    final syncIntervalController = TextEditingController(text: currentSettings.syncInterval.toString());
    bool allowBackgroundRunning = currentSettings.allowBackgroundRunning;
    
    // 气泡颜色设置 - 浅色模式
    Color lightUserBubbleColor = currentSettings.lightUserBubbleColor;
    Color lightAiBubbleColor = currentSettings.lightAiBubbleColor;
    Color lightSelectedBubbleColor = currentSettings.lightSelectedBubbleColor;
    
    // 气泡颜色设置 - 深色模式
    Color darkUserBubbleColor = currentSettings.darkUserBubbleColor;
    Color darkAiBubbleColor = currentSettings.darkAiBubbleColor;
    Color darkSelectedBubbleColor = currentSettings.darkSelectedBubbleColor;
    
    // 兼容性属性
    Color userBubbleColor = currentSettings.userBubbleColor;
    Color aiBubbleColor = currentSettings.aiBubbleColor;
    Color selectedBubbleColor = currentSettings.selectedBubbleColor;

    bool testing = false;
    String? testResult;
    
    // 自动保存延迟器
    Timer? autoSaveTimer;
    
    // 自动保存设置
    void autoSaveSettings() {
      // 取消之前的定时器
      autoSaveTimer?.cancel();
      
      // 设置新的定时器，延迟1秒后自动保存
      autoSaveTimer = Timer(const Duration(seconds: 1), () async {
        try {
          // 自动保存设置
          
          final apiBaseUrl = apiBaseUrlController.text.trim();
          final apiKey = apiKeyController.text.trim();
          final userId = userIdController.text.trim();
          final proxyHost = proxyHostController.text.trim();
          final proxyPort = proxyPortController.text.trim().isNotEmpty
              ? int.tryParse(proxyPortController.text.trim())
              : null;
          final proxyUser = proxyUserController.text.trim();
          final proxyPassword = proxyPasswordController.text.trim();
          final syncInterval = int.tryParse(syncIntervalController.text.trim()) ?? 3;
          
          // 更新当前设置对象
          currentSettings.apiBaseUrl = apiBaseUrl;
          currentSettings.apiKey = apiKey;
          currentSettings.userId = userId;
          currentSettings.proxyHost = proxyHost.isNotEmpty ? proxyHost : null;
          currentSettings.proxyPort = proxyPort;
          currentSettings.proxyUser = proxyUser.isNotEmpty ? proxyUser : null;
          currentSettings.proxyPassword = proxyPassword.isNotEmpty ? proxyPassword : null;
          currentSettings.syncInterval = syncInterval;
          currentSettings.allowBackgroundRunning = allowBackgroundRunning;
          
          // 更新新的颜色字段
          currentSettings.lightUserBubbleColor = lightUserBubbleColor;
          currentSettings.lightAiBubbleColor = lightAiBubbleColor;
          currentSettings.lightSelectedBubbleColor = lightSelectedBubbleColor;
          currentSettings.darkUserBubbleColor = darkUserBubbleColor;
          currentSettings.darkAiBubbleColor = darkAiBubbleColor;
          currentSettings.darkSelectedBubbleColor = darkSelectedBubbleColor;
          
          // 兼容性字段
          currentSettings.userBubbleColor = userBubbleColor;
          currentSettings.aiBubbleColor = aiBubbleColor;
          currentSettings.selectedBubbleColor = selectedBubbleColor;
          
          // 保存设置并通知监听器
          await currentSettings.saveToPrefs();
          
          // 设置已自动保存
    } catch (e) {
      // 自动保存设置时出错
          
          // 显示错误消息
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('保存设置时出错: $e'), 
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              )
            );
          }
        }
      });
    }
    
    // 添加文本字段监听器
    apiBaseUrlController.addListener(autoSaveSettings);
    apiKeyController.addListener(autoSaveSettings);
    userIdController.addListener(autoSaveSettings);
    proxyHostController.addListener(autoSaveSettings);
    proxyPortController.addListener(autoSaveSettings);
    proxyUserController.addListener(autoSaveSettings);
    proxyPasswordController.addListener(autoSaveSettings);
    syncIntervalController.addListener(autoSaveSettings);
    
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('应用设置'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: apiBaseUrlController, decoration: const InputDecoration(labelText: 'API Base URL')),
                  TextField(controller: apiKeyController, decoration: const InputDecoration(labelText: 'API Key'), obscureText: true),
                  TextField(controller: userIdController, decoration: const InputDecoration(labelText: 'User ID')),
                  const Divider(),
                  const Text('代理设置 (可选)', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextField(controller: proxyHostController, decoration: const InputDecoration(labelText: '代理地址')),
                  TextField(controller: proxyPortController, decoration: const InputDecoration(labelText: '端口'), keyboardType: TextInputType.number),
                  TextField(controller: proxyUserController, decoration: const InputDecoration(labelText: '用户名')),
                  TextField(controller: proxyPasswordController, decoration: const InputDecoration(labelText: '密码'), obscureText: true),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: testing ? null : () async {
                      setState(() {
                        testing = true;
                        testResult = null;
                      });
                      
                      final result = await currentSettings.testConnectivity(
                        testApiBaseUrl: apiBaseUrlController.text,
                        testApiKey: apiKeyController.text,
                        testUserId: userIdController.text,
                        testProxyHost: proxyHostController.text,
                        testProxyPort: proxyPortController.text,
                        testProxyUser: proxyUserController.text,
                        testProxyPassword: proxyPasswordController.text,
                      );
                      
                      setState(() {
                        testResult = result ?? '连通性检测成功';
                        testing = false;
                      });
                    },
                    child: testing 
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) 
                        : const Text('检测连通性'),
                  ),
                  const Divider(),
                  const Text('同步设置', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextField(
                    controller: syncIntervalController, 
                    decoration: const InputDecoration(
                      labelText: '云同步刷新间隔 (秒)', 
                      hintText: '设置为0关闭自动同步'
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '提示: 设置为0时将关闭自动同步，可在对话列表下拉手动刷新\n'
                    '较短的同步间隔可能导致图片频繁加载，建议设置为10秒或更长', 
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))
                  ),
                  const Divider(),
                  const Text('后台运行设置', style: TextStyle(fontWeight: FontWeight.bold)),
                  SwitchListTile(
                    title: const Text('允许后台运行'),
                    subtitle: const Text('按返回键时最小化应用而不是退出'),
                    value: allowBackgroundRunning,
                    onChanged: (bool value) {
                      setState(() {
                        allowBackgroundRunning = value;
                      });
                      autoSaveSettings();
                    },
                  ),
                  const Divider(),
                  const Text('气泡颜色设置', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('恢复默认颜色'),
                        onPressed: () {
                          setState(() {
                            // 浅色模式默认颜色
                            lightUserBubbleColor = const Color(0xFF2196F3);  // 蓝色
                            lightAiBubbleColor = const Color(0xFFF5F5F5);   // 浅灰色
                            lightSelectedBubbleColor = const Color(0xFFBBDEFB); // 浅蓝色
                            
                            // 深色模式默认颜色
                            darkUserBubbleColor = const Color(0xFF1976D2);   // 深蓝色
                            darkAiBubbleColor = const Color(0xFF424242);    // 深灰色
                            darkSelectedBubbleColor = const Color(0xFF1565C0); // 深蓝色
                          });
                          autoSaveSettings();
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                  const Text('浅色模式气泡颜色', style: TextStyle(fontWeight: FontWeight.bold)),
                  ListTile(
                    title: const Text('用户气泡颜色'),
                    trailing: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: lightUserBubbleColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Theme.of(context).colorScheme.outline),
                      ),
                    ),
                    onTap: () async {
                      final Color? pickedColor = await showDialog<Color>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('选择浅色模式用户气泡颜色'),
                            content: SingleChildScrollView(
                              child: ColorPicker(
                                pickerColor: lightUserBubbleColor,
                                onColorChanged: (Color color) {
                                  setState(() {
                                    lightUserBubbleColor = color;
                                    userBubbleColor = color; // 兼容性
                                  });
                                },
                                enableAlpha: true,
                                labelTypes: const [],
                                pickerAreaHeightPercent: 0.8,
                              ),
                            ),
                            actions: <Widget>[
                              TextButton(
                                child: const Text('确定'),
                                onPressed: () {
                                  Navigator.of(context).pop(lightUserBubbleColor);
                                },
                              ),
                            ],
                          );
                        },
                      );
                      if (pickedColor != null) {
                        setState(() {
                          lightUserBubbleColor = pickedColor;
                          userBubbleColor = pickedColor; // 兼容性
                        });
                        autoSaveSettings();
                      }
                    },
                  ),
                  ListTile(
                    title: const Text('AI气泡颜色'),
                    trailing: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: lightAiBubbleColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Theme.of(context).colorScheme.outline),
                      ),
                    ),
                    onTap: () async {
                      final Color? pickedColor = await showDialog<Color>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('选择浅色模式AI气泡颜色'),
                            content: SingleChildScrollView(
                              child: ColorPicker(
                                pickerColor: lightAiBubbleColor,
                                onColorChanged: (Color color) {
                                  setState(() {
                                    lightAiBubbleColor = color;
                                    aiBubbleColor = color; // 兼容性
                                  });
                                },
                                enableAlpha: true,
                                labelTypes: const [],
                                pickerAreaHeightPercent: 0.8,
                              ),
                            ),
                            actions: <Widget>[
                              TextButton(
                                child: const Text('确定'),
                                onPressed: () {
                                  Navigator.of(context).pop(lightAiBubbleColor);
                                },
                              ),
                            ],
                          );
                        },
                      );
                      if (pickedColor != null) {
                        setState(() {
                          lightAiBubbleColor = pickedColor;
                          aiBubbleColor = pickedColor; // 兼容性
                        });
                        autoSaveSettings();
                      }
                    },
                  ),
                  ListTile(
                    title: const Text('选中气泡颜色'),
                    subtitle: const Text('长按消息时显示的颜色'),
                    trailing: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: lightSelectedBubbleColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Theme.of(context).colorScheme.outline),
                      ),
                    ),
                    onTap: () async {
                      final Color? pickedColor = await showDialog<Color>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('选择浅色模式选中气泡颜色'),
                            content: SingleChildScrollView(
                              child: ColorPicker(
                                pickerColor: lightSelectedBubbleColor,
                                onColorChanged: (Color color) {
                                  setState(() {
                                    lightSelectedBubbleColor = color;
                                    selectedBubbleColor = color; // 兼容性
                                  });
                                },
                                enableAlpha: true,
                                labelTypes: const [],
                                pickerAreaHeightPercent: 0.8,
                              ),
                            ),
                            actions: <Widget>[
                              TextButton(
                                child: const Text('确定'),
                                onPressed: () {
                                  Navigator.of(context).pop(lightSelectedBubbleColor);
                                },
                              ),
                            ],
                          );
                        },
                      );
                      if (pickedColor != null) {
                        setState(() {
                          lightSelectedBubbleColor = pickedColor;
                          selectedBubbleColor = pickedColor; // 兼容性
                        });
                        autoSaveSettings();
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('深色模式气泡颜色', style: TextStyle(fontWeight: FontWeight.bold)),
                  ListTile(
                    title: const Text('用户气泡颜色'),
                    trailing: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: darkUserBubbleColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Theme.of(context).colorScheme.outline),
                      ),
                    ),
                    onTap: () async {
                      final Color? pickedColor = await showDialog<Color>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('选择深色模式用户气泡颜色'),
                            content: SingleChildScrollView(
                              child: ColorPicker(
                                pickerColor: darkUserBubbleColor,
                                onColorChanged: (Color color) {
                                  setState(() {
                                    darkUserBubbleColor = color;
                                  });
                                },
                                enableAlpha: true,
                                labelTypes: const [],
                                pickerAreaHeightPercent: 0.8,
                              ),
                            ),
                            actions: <Widget>[
                              TextButton(
                                child: const Text('确定'),
                                onPressed: () {
                                  Navigator.of(context).pop(darkUserBubbleColor);
                                },
                              ),
                            ],
                          );
                        },
                      );
                      if (pickedColor != null) {
                        setState(() {
                          darkUserBubbleColor = pickedColor;
                        });
                        autoSaveSettings();
                      }
                    },
                  ),
                  ListTile(
                    title: const Text('AI气泡颜色'),
                    trailing: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: darkAiBubbleColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Theme.of(context).colorScheme.outline),
                      ),
                    ),
                    onTap: () async {
                      final Color? pickedColor = await showDialog<Color>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('选择深色模式AI气泡颜色'),
                            content: SingleChildScrollView(
                              child: ColorPicker(
                                pickerColor: darkAiBubbleColor,
                                onColorChanged: (Color color) {
                                  setState(() {
                                    darkAiBubbleColor = color;
                                  });
                                },
                                enableAlpha: true,
                                labelTypes: const [],
                                pickerAreaHeightPercent: 0.8,
                              ),
                            ),
                            actions: <Widget>[
                              TextButton(
                                child: const Text('确定'),
                                onPressed: () {
                                  Navigator.of(context).pop(darkAiBubbleColor);
                                },
                              ),
                            ],
                          );
                        },
                      );
                      if (pickedColor != null) {
                        setState(() {
                          darkAiBubbleColor = pickedColor;
                        });
                        autoSaveSettings();
                      }
                    },
                  ),
                  ListTile(
                    title: const Text('选中气泡颜色'),
                    subtitle: const Text('长按消息时显示的颜色'),
                    trailing: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: darkSelectedBubbleColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Theme.of(context).colorScheme.outline),
                      ),
                    ),
                    onTap: () async {
                      final Color? pickedColor = await showDialog<Color>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('选择深色模式选中气泡颜色'),
                            content: SingleChildScrollView(
                              child: ColorPicker(
                                pickerColor: darkSelectedBubbleColor,
                                onColorChanged: (Color color) {
                                  setState(() {
                                    darkSelectedBubbleColor = color;
                                  });
                                },
                                enableAlpha: true,
                                labelTypes: const [],
                                pickerAreaHeightPercent: 0.8,
                              ),
                            ),
                            actions: <Widget>[
                              TextButton(
                                child: const Text('确定'),
                                onPressed: () {
                                  Navigator.of(context).pop(darkSelectedBubbleColor);
                                },
                              ),
                            ],
                          );
                        },
                      );
                      if (pickedColor != null) {
                        setState(() {
                          darkSelectedBubbleColor = pickedColor;
                        });
                        autoSaveSettings();
                      }
                    },
                  ),
                  if (testResult != null) Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      testResult!,
                      style: TextStyle(
                        color: testResult! == '连通性检测成功' ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // 取消自动保存定时器
                  autoSaveTimer?.cancel();
                  
                  // 关闭对话框
                  Navigator.pop(context);
                },
                child: const Text('关闭'),
              ),
            ],
          ),
        );
      },
    );
    
    // 释放资源
    apiBaseUrlController.dispose();
    apiKeyController.dispose();
    userIdController.dispose();
    proxyHostController.dispose();
    proxyPortController.dispose();
    proxyUserController.dispose();
    proxyPasswordController.dispose();
    syncIntervalController.dispose();
    autoSaveTimer?.cancel();
    
    return currentSettings;
  }

  // 检查对话列表是否有变化
  bool checkConversationsChanged(List<Conversation> local, List<Conversation> remote) {
    if (local.length != remote.length) return true;
    
    // 创建ID到对话的映射以便快速查找
    final localMap = {for (var c in local) c.id: c};
    
    for (var remoteConv in remote) {
      final localConv = localMap[remoteConv.id];
      
      // 如果本地没有这个对话，或者对话的名称或更新时间不同，则有变化
      if (localConv == null || 
          localConv.name != remoteConv.name || 
          localConv.updatedAt.millisecondsSinceEpoch != remoteConv.updatedAt.millisecondsSinceEpoch) {
        return true;
      }
    }
    
    return false;
  }

  @override
  void dispose() {
    // 不要清除静态缓存，因为它可能在其他地方被使用
    // 只需要通知监听器
    super.dispose();
  }
}