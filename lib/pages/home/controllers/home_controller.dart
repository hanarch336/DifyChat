import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_dify/models/message.dart';
import 'package:flutter_dify/managers/conversation_manager.dart';
import 'package:flutter_dify/managers/message_handler.dart';
export 'package:flutter_dify/managers/message_handler.dart' show ChatUploadFile;
import 'package:flutter_dify/managers/scroll_manager.dart';
import 'package:flutter_dify/managers/selection_manager.dart';
import 'package:flutter_dify/managers/settings_manager.dart';
import 'package:flutter_dify/managers/system_tray_manager.dart';
import 'package:flutter_dify/services/performance_optimizer.dart';
import 'package:flutter_dify/services/platform_bridge.dart';
import 'package:flutter_dify/main.dart' show globalSystemTrayManager;
import 'package:provider/provider.dart';

class HomeController with WidgetsBindingObserver {
  ConversationManager? conversationManager;
  ChatMessageHandler? messageHandler;
  SettingsManager? settingsManager;
  late ScrollManager scrollManager;
  SystemTrayManager? systemTrayManager;
  late SelectionManager selectionManager;
  
  final PerformanceOptimizer performanceOptimizer = PerformanceOptimizer();
  final PlatformBridge platformBridge = PlatformBridge();
  
  final TextEditingController textController = TextEditingController();
  late ScrollController scrollController;
  late ScrollController drawerScrollController;
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final FocusNode focusNode = FocusNode();
  final FocusNode textFieldFocusNode = FocusNode();
  
  Offset? panStartPosition;
  
  bool isDrawerOpen = false;
  double drawerOffset = 0.0;
  bool isAnimating = false;
  
  Timer? _throttleTimer;
  
  late StreamController<List<Message>> messagesStreamController;
  
  final List<ChatUploadFile> uploadFiles = [];
  bool isUploadingFiles = false;
  
  Timer? refreshTimer;
  Timer? autoRefreshTimer;
  
  Isolate? backgroundIsolate;
  ReceivePort? receivePort;
  
  late Function(VoidCallback) _setState;
  late BuildContext _context;
  
  void updateUI() {
    _throttledSetState();
  }
  
  void updateUIImmediate() {
    _setState(() {});
  }

  void initialize(BuildContext context, Function(VoidCallback) setState) {
    _context = context;
    _setState = setState;
    
    WidgetsBinding.instance.addObserver(this);
    performanceOptimizer.initialize();
    
    messagesStreamController = StreamController<List<Message>>.broadcast();
    messagesStreamController.stream.listen((_) {
      _setState(() {});
    });
    
    scrollController = ScrollController();
    drawerScrollController = ScrollController();
    
    _initializeManagers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _postFrameInitialization();
    });
  }
  
  void _initializeManagers() {
    selectionManager = SelectionManager();
    selectionManager.onStateChanged = () {
      updateUIImmediate();
    };
    
    scrollManager = ScrollManager(scrollController: scrollController);
    scrollManager.onStateChanged = () {
      updateUI();
    };
    scrollManager.initialize();
    
    settingsManager = Provider.of<SettingsManager>(_context, listen: false);
    
    if (settingsManager!.isApiConfigured) {
      _initializeConversationManager();
    }
    
    // 使用全局系统托盘管理器
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // 从main.dart导入全局系统托盘管理器
      systemTrayManager = globalSystemTrayManager;
    }
  }
  
  void _initializeConversationManager() {
    conversationManager = ConversationManager(
      conversationApi: settingsManager!.createApiClient(),
      messagesStreamController: messagesStreamController,
      showTopSnackBar: showTopSnackBar,
    );
    
    conversationManager!.onStateChanged = () {
      updateUIImmediate();
    };
    

    conversationManager!.setBackgroundCheckCallback(() => _isInBackground);
    
    messageHandler = ChatMessageHandler(
      conversationApi: settingsManager!.createApiClient(),
      messagesStreamController: messagesStreamController,
      showTopSnackBar: showTopSnackBar,

      onNewConversationCreated: (conversationId) {
        conversationManager?.setCurrentConversationById(conversationId);
      },
    );
    
    messageHandler!.setBackgroundCheckCallback(() => _isInBackground);
    
    conversationManager!.loadConversations();
    _restoreLastConversation();
  }
  
  void reinitializeApiClients() {
    if (settingsManager!.isApiConfigured) {
      if (conversationManager == null || messageHandler == null) {
        _initializeConversationManager();
      } else {
        final newApiClient = settingsManager!.createApiClient();
        

        conversationManager!.setBackgroundCheckCallback(() => _isInBackground);
        
        conversationManager!.updateApiClient(newApiClient);
        messageHandler!.updateApiClient(newApiClient);
        messageHandler!.setBackgroundCheckCallback(() => _isInBackground);
        conversationManager!.loadConversations();
      }
      
      _setState(() {});
    }
  }
  
  void _postFrameInitialization() {
    _startBackgroundProcessing();
    _setupAutoRefresh();
    _preloadData();
  }
  
  void _startBackgroundProcessing() {
  }
  
  void _setupAutoRefresh() {
    autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (conversationManager != null) {
        if (conversationManager!.currentConversation != null) {
          conversationManager!.fetchRemoteMessages(conversationManager!.currentConversation!.id);
        }
      }
    });
  }
  
  void _preloadData() {
    if (conversationManager != null) {
      conversationManager!.loadConversations();
    }
  }
  
  void showTopSnackBar(String message, {bool isError = false}) {
    if (!_context.mounted) return;
    
    ScaffoldMessenger.of(_context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(top: 80, left: 16, right: 16),
      ),
    );
  }
  
  bool get isLoading => messageHandler?.isMessageSending ?? false;
  
  void setIsUploadingFiles(bool uploading) {
    isUploadingFiles = uploading;
    updateUI();
  }
  
  Future<bool> onWillPop() async {
    if (selectionManager.isSelectionMode) {
      selectionManager.exitSelectionMode();
      _setState(() {});
      return false;
    }
    if (isDrawerOpen && (Platform.isAndroid || Platform.isIOS)) {
      closeDrawer();
      return false;
    }
    return true;
  }
  
  void updateDrawerOffset(double offset) {
    final newOffset = offset.clamp(0.0, 280.0);
    if (newOffset != drawerOffset) {
      drawerOffset = newOffset;
      isAnimating = false;
      _setState(() {});
    }
  }
  void _throttledSetState() {
    if (_throttleTimer?.isActive ?? false) return;
    
    _throttleTimer = Timer(const Duration(milliseconds: 32), () {
      _setState(() {});
    });
  }
  
  void openDrawer() {
    isDrawerOpen = true;
    drawerOffset = 280.0;
    isAnimating = true;
    _setState(() {});
    
    Timer(const Duration(milliseconds: 250), () {
      isAnimating = false;
      _setState(() {});
    });
  }

  void closeDrawer() {
    isDrawerOpen = false;
    drawerOffset = 0.0;
    isAnimating = true;
    _setState(() {});
    
    Timer(const Duration(milliseconds: 250), () {
      isAnimating = false;
      _setState(() {});
    });
  }
  
  void toggleDrawer() {
    if (isDrawerOpen) {
      closeDrawer();
    } else {
      openDrawer();
    }
  }
  
  bool _isInBackground = false;
  
  void handleAppLifecycleChange(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (_isInBackground) {
          _isInBackground = false;
          if (conversationManager != null) {
            if (conversationManager!.currentConversation != null) {
              conversationManager!.fetchRemoteMessages(conversationManager!.currentConversation!.id);
            }
          }
        }
        break;
      case AppLifecycleState.paused:
        _isInBackground = true;
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.hidden:
        _isInBackground = true;
        break;
    }
  }
  
  Future<void> minimizeToBackground() async {
    try {
      _isInBackground = true;
      final success = await platformBridge.minimizeApp();
      if (!success) {
        if (Platform.isAndroid || Platform.isIOS) {
          SystemNavigator.pop();
        }
      }
    } catch (e) {
      if (Platform.isAndroid || Platform.isIOS) {
        SystemNavigator.pop();
      }
    }
  }
  

  void dispose() {
    textController.dispose();
    scrollController.dispose();
    drawerScrollController.dispose();
    focusNode.dispose();
    textFieldFocusNode.dispose();
    messagesStreamController.close();
    
    refreshTimer?.cancel();
    autoRefreshTimer?.cancel();
    _throttleTimer?.cancel();
    
    backgroundIsolate?.kill();
    receivePort?.close();
    
    systemTrayManager?.dispose();
    
    WidgetsBinding.instance.removeObserver(this);
  }
  
  Future<void> _restoreLastConversation() async {
  }
}