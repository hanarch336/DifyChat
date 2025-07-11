import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dify/models/message.dart';
import 'package:flutter_dify/pages/home/controllers/home_controller.dart';
import 'package:flutter_dify/widgets/message_bubble.dart';
import 'package:flutter_dify/pages/settings/settings_page.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dify/managers/settings_manager.dart';

class HomeBody extends StatefulWidget {
  final HomeController controller;
  final bool isApiConfigured;

  const HomeBody({
    Key? key,
    required this.controller,
    required this.isApiConfigured,
  }) : super(key: key);

  @override
  State<HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> with TickerProviderStateMixin {
  bool _showScrollToBottomButton = false;
  bool _isUserScrolling = false;
  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonAnimation;
  Timer? _scrollEndTimer;

  @override
  void initState() {
    super.initState();
    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _buttonAnimation = CurvedAnimation(
      parent: _buttonAnimationController,
      curve: Curves.easeInOut,
    );
    _setupScrollListener();
  }

  @override
  void dispose() {
    _buttonAnimationController.dispose();
    _scrollEndTimer?.cancel();
    super.dispose();
  }

  void _setupScrollListener() {
    widget.controller.scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final scrollController = widget.controller.scrollController;
    if (!scrollController.hasClients) return;

    final isAtBottom = scrollController.offset <= 100;
    
    _isUserScrolling = true;
    _scrollEndTimer?.cancel();
    _scrollEndTimer = Timer(const Duration(milliseconds: 500), () {
      _isUserScrolling = false;
      _updateButtonVisibility();
    });

    final messages = widget.controller.conversationManager?.currentMessages ?? [];
    final shouldShow = messages.isNotEmpty && !isAtBottom && !_isUserScrolling;
    
    if (shouldShow != _showScrollToBottomButton) {
      setState(() {
        _showScrollToBottomButton = shouldShow;
      });
      
      if (shouldShow) {
        _buttonAnimationController.forward();
      } else {
        _buttonAnimationController.reverse();
      }
    }
  }

  void _updateButtonVisibility() {
    final scrollController = widget.controller.scrollController;
    if (!scrollController.hasClients) return;

    final isAtBottom = scrollController.offset <= 100;
    final messages = widget.controller.conversationManager?.currentMessages ?? [];
    final shouldShow = messages.isNotEmpty && !isAtBottom && !_isUserScrolling;
    
    if (shouldShow != _showScrollToBottomButton) {
      setState(() {
        _showScrollToBottomButton = shouldShow;
      });
      
      if (shouldShow) {
        _buttonAnimationController.forward();
      } else {
        _buttonAnimationController.reverse();
      }
    }
  }

  void _scrollToBottom() {
    final scrollController = widget.controller.scrollController;
    if (scrollController.hasClients) {
      scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isApiConfigured) {
      return _buildConfigurationPrompt(context);
    }

    return StreamBuilder<List<Message>>(
      stream: widget.controller.messagesStreamController.stream,
      builder: (context, snapshot) {
        final messages = widget.controller.conversationManager?.currentMessages ?? [];
        
        if (messages.isEmpty) {
          return _buildEmptyState(context);
        }

        return _buildMessagesList(context, messages);
      },
    );
  }

  Widget _buildConfigurationPrompt(BuildContext context) {
    final settingsManager = Provider.of<SettingsManager>(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.settings,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              '欢迎使用 DifyChat',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '请先配置 API 设置以开始使用',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _openSettings(context, settingsManager),
              icon: const Icon(Icons.settings),
              label: const Text('打开设置'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              '开始新的对话',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '在下方输入框中输入消息开始对话',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList(BuildContext context, List<Message> messages) {
    return Stack(
      children: [
        ListView.builder(
          controller: widget.controller.scrollController,
          reverse: true,
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          itemCount: messages.length,
          itemBuilder: (context, index) {

            final reversedIndex = messages.length - 1 - index;
            final message = messages[reversedIndex];
            final isSelected = widget.controller.selectionManager.isMessageSelected(message.id);
            
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 2.0),
              decoration: isSelected
                  ? BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.0),
                    )
                  : null,
              child: MessageBubble(
                message: message,
                isSelectionMode: widget.controller.selectionManager.isSelectionMode,
                onSelectionChanged: (isSelected) {
                  if (!widget.controller.selectionManager.isSelectionMode) {
                    widget.controller.selectionManager.enterSelectionMode();
                  }
                  widget.controller.selectionManager.toggleMessageSelection(message.id);
                },
              ),
            );
          },
        ),



        _buildScrollToBottomButton(context),
      ],
    );
  }

  Widget _buildScrollToBottomButton(BuildContext context) {
    return AnimatedBuilder(
      animation: _buttonAnimation,
      builder: (context, child) {
        return Positioned(
          bottom: 100,
          right: 16,
          child: Transform.scale(
            scale: _buttonAnimation.value,
            child: Opacity(
              opacity: _buttonAnimation.value,
              child: FloatingActionButton(
                backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.9),
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                elevation: 4,
                onPressed: _scrollToBottom,
                child: const Icon(
                  Icons.keyboard_arrow_down,
                  size: 28,
                ),
              ),
            ),
          ),
        );
      },
    );
  }



  void _openSettings(BuildContext context, SettingsManager settingsManager) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SettingsPage(
          settingsManager: settingsManager,
          conversationManager: widget.controller.conversationManager,
          onSettingsChanged: (newSettings) async {

            await newSettings.saveToPrefs();

            SettingsManager.cachedSettings = newSettings;

            settingsManager.apiBaseUrl = newSettings.apiBaseUrl;
            settingsManager.apiKey = newSettings.apiKey;
            settingsManager.userId = newSettings.userId;
            settingsManager.proxyHost = newSettings.proxyHost;
            settingsManager.proxyPort = newSettings.proxyPort;
            settingsManager.proxyUser = newSettings.proxyUser;
            settingsManager.proxyPassword = newSettings.proxyPassword;
            settingsManager.syncInterval = newSettings.syncInterval;
            settingsManager.allowBackgroundRunning = newSettings.allowBackgroundRunning;
            settingsManager.userBubbleColor = newSettings.userBubbleColor;
            settingsManager.aiBubbleColor = newSettings.aiBubbleColor;
            settingsManager.selectedBubbleColor = newSettings.selectedBubbleColor;
            await settingsManager.saveToPrefs();

            widget.controller.reinitializeApiClients();
          },
        ),
      ),
    );
  }
}