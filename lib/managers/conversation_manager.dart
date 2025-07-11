import 'dart:async';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:flutter_dify/models/conversation.dart';
import 'package:flutter_dify/models/message.dart';
import 'package:flutter_dify/services/conversation_api.dart';
import 'package:flutter_dify/services/conversation_cache.dart';
import 'package:flutter_dify/managers/settings_manager.dart';

class ConversationManager {
  ConversationApi conversationApi;
  final StreamController<List<Message>> messagesStreamController;
  final Function(String, {bool isError}) showTopSnackBar;
  
  List<Conversation> _conversations = [];
  Conversation? currentConversation;
  List<Message> _currentMessages = [];
  bool _loading = false;
  bool _isRefreshing = false;
  bool _isManualRefreshing = false;
  bool allowSync = true;
  
  int _messageRefreshCounter = 0;
  VoidCallback? onStateChanged;
  bool Function()? _isInBackgroundCallback;
  
  ConversationManager({
    required this.conversationApi,
    required this.messagesStreamController,
    required this.showTopSnackBar,
  });
  
  List<Conversation> get conversations => _conversations;
  List<Message> get currentMessages => _currentMessages;
  bool get isLoading => _loading;
  bool get isRefreshing => _isRefreshing;
  bool get isManualRefreshing => _isManualRefreshing;
  set currentMessages(List<Message> value) {
    _currentMessages = value;
    messagesStreamController.add(List.from(_currentMessages));
  }
  
  void updateApiClient(ConversationApi newApiClient) {
    conversationApi = newApiClient;
  }
  

  
  void setBackgroundCheckCallback(bool Function() callback) {
    _isInBackgroundCallback = callback;
  }
  
  Future<void> loadConversations() async {
    if (_loading) return;
    _loading = true;
    
    try {
      final cachedConversations = await ConversationCache.getConversations();
      if (cachedConversations.isNotEmpty) {
        _conversations = cachedConversations;
        
        final savedConversationId = await SettingsManager.getCurrentConversationId();
        if (savedConversationId != null && savedConversationId.isNotEmpty) {
          currentConversation = _conversations.firstWhereOrNull((c) => c.id == savedConversationId) ?? 
                              (_conversations.isNotEmpty ? _conversations.first : null);
        } else {
          currentConversation = _conversations.isNotEmpty ? _conversations.first : null;
        }
    
        if (currentConversation != null) {
          final cachedMessages = await ConversationCache.getMessages(currentConversation!.id);
          if (cachedMessages.isNotEmpty) {
            _currentMessages = cachedMessages;
            messagesStreamController.add(List.from(_currentMessages));
          }
        }
        
        messagesStreamController.add(List.from(_currentMessages));
      }
      
      _loading = false;
      _fetchRemoteConversationsInBackground();
    } catch (e) {
      _loading = false;
    }
  }
  
  Future<void> _fetchRemoteConversationsInBackground() async {
    try {
      await fetchRemoteConversations();
    } catch (e) {
      // Ignore background fetch failures
    }
  }
  Future<void> fetchRemoteConversations() async {
    try {
      final serverConversations = await conversationApi.fetchConversations();
      bool hasChanges = checkConversationsChanged(_conversations, serverConversations);
      
      if (hasChanges) {
        final currentId = currentConversation?.id;
        _conversations = serverConversations;
        _loading = false;
        
        if (currentId != null) {
          currentConversation = _conversations.firstWhereOrNull((c) => c.id == currentId) ?? 
                              (_conversations.isNotEmpty ? _conversations.first : null);
        } else if (currentConversation == null && _conversations.isNotEmpty) {
          currentConversation = _conversations.first;
        }
        
        await ConversationCache.saveConversations(serverConversations);
        
        if (currentConversation != null) {
          await fetchRemoteMessages(currentConversation!.id);
        }
        
        messagesStreamController.add(List.from(_currentMessages));
      } else {
        if (_loading) {
          _loading = false;
        }
      }
    } catch (e) {
      _loading = false;
    }
  }
  
  Future<void> loadMessages(String conversationId) async {
    try {
      final cachedMessages = await ConversationCache.loadMessages(conversationId);
      
      if (cachedMessages.isNotEmpty) {
        _currentMessages = cachedMessages;
        _loading = false;
        messagesStreamController.add(List.from(_currentMessages));
      }
    } catch (e) {
      // Ignore cache loading failures
    }
    
    fetchRemoteMessages(conversationId);
  }
  
  Future<void> fetchRemoteMessages(String conversationId) async {
    if (!allowSync) return;
    if (_isInBackgroundCallback?.call() == true) return;
    
    try {
      final serverMessages = await conversationApi.getMessages(conversationId);
      
      if (currentConversation?.id != conversationId) return;
      
      bool hasChanges = checkMessagesChanged(_currentMessages, serverMessages);
      
      if (hasChanges) {
        final Map<String, MessageStatus> messageStatuses = {};
        for (var msg in _currentMessages) {
          messageStatuses[msg.id] = msg.status;
        }
        
        final List<Message> updatedMessages = serverMessages.map((msg) {
          if (messageStatuses.containsKey(msg.id)) {
            return msg.copyWith(status: messageStatuses[msg.id]);
          }
          return msg;
        }).toList();
        
        _currentMessages = updatedMessages;
        _loading = false;
        
        messagesStreamController.add(List.from(_currentMessages));
        await ConversationCache.saveMessages(conversationId, _currentMessages);
      } else if (_loading) {
        _loading = false;
      }
    } catch (e) {
      if (_loading && currentConversation?.id == conversationId) {
        _loading = false;
      }
    }
  }
  
  void setCurrentConversationById(String conversationId) {
    final existingConversation = _conversations.firstWhere(
      (conv) => conv.id == conversationId,
      orElse: () => Conversation(
        id: conversationId,
        name: '新对话',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    
    if (!_conversations.any((conv) => conv.id == conversationId)) {
      _conversations.insert(0, existingConversation);
    }
    
    currentConversation = existingConversation;
    _updateConversationFromServer(conversationId);
  }
  
  Future<void> _updateConversationFromServer(String conversationId) async {
    try {
      final serverConversations = await conversationApi.fetchConversations();
      final serverConversation = serverConversations.firstWhere(
        (conv) => conv.id == conversationId,
        orElse: () => Conversation(
          id: conversationId,
          name: '新对话',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      
      final index = _conversations.indexWhere((conv) => conv.id == conversationId);
      if (index != -1) {
        _conversations[index] = serverConversation;
        if (currentConversation?.id == conversationId) {
          currentConversation = serverConversation;
        }
      }
    } catch (e) {
      // Update conversation info failed
    }
  }
  
  Future<void> switchConversation(Conversation conversation) async {
    if (currentConversation != null && currentConversation!.id == conversation.id) {
      return;
    }
    
    final String targetConversationId = conversation.id;
    currentConversation = conversation;
    _saveCurrentConversationId(conversation.id);
    
    _currentMessages = [];
    messagesStreamController.add([]);
    _loading = true;
    
    try {
      final cachedMessages = await ConversationCache.getMessages(targetConversationId);
      
      // 确保用户没有在此期间切换到其他对话
      if (currentConversation?.id != targetConversationId) return;
      
      if (cachedMessages.isNotEmpty) {
        _currentMessages = cachedMessages;
        _loading = false;
        
        messagesStreamController.add(List.from(_currentMessages));
      }
      
      // 然后从服务器获取最新消息
      await fetchRemoteMessages(targetConversationId);
    } catch (e) {
      // 切换对话失败
      if (currentConversation?.id == targetConversationId) {
        _loading = false;
      }
    }
  }
  
  // 删除对话
  Future<void> deleteConversation(Conversation conversation) async {
    try {
      await conversationApi.deleteConversation(conversation.id);
      
      // 立即从本地列表中移除
      _conversations.removeWhere((conv) => conv.id == conversation.id);
      
      // 如果删除的是当前对话，切换到第一个对话或清空
      if (currentConversation?.id == conversation.id) {
        currentConversation = _conversations.isNotEmpty ? _conversations.first : null;
        _currentMessages = [];
        
        messagesStreamController.add(List.from(_currentMessages));
        
        if (currentConversation != null) {
          await loadMessages(currentConversation!.id);
        }
      }
      
      await ConversationCache.saveConversations(_conversations);
      showTopSnackBar('对话已删除');
    } catch (e) {
      showTopSnackBar('删除对话失败: $e', isError: true);
    }
  }

  Future<void> batchDeleteConversations(List<Conversation> conversations) async {
    if (conversations.isEmpty) return;
    
    try {
      showTopSnackBar('正在删除 ${conversations.length} 个对话...');
      
      final List<String> failedIds = [];
      for (final conversation in conversations) {
        try {
          await conversationApi.deleteConversation(conversation.id);
          _conversations.removeWhere((conv) => conv.id == conversation.id);
        } catch (e) {
          failedIds.add(conversation.id);
        }
      }
      
      final deletedCurrentConversation = conversations.any((conv) => conv.id == currentConversation?.id);
      if (deletedCurrentConversation) {
        currentConversation = _conversations.isNotEmpty ? _conversations.first : null;
        _currentMessages = [];
        messagesStreamController.add(List.from(_currentMessages));
        
        if (currentConversation != null) {
          await loadMessages(currentConversation!.id);
        }
      }
      
      await ConversationCache.saveConversations(_conversations);
      
      if (failedIds.isEmpty) {
        showTopSnackBar('成功删除 ${conversations.length} 个对话');
      } else {
        final successCount = conversations.length - failedIds.length;
        showTopSnackBar('删除完成：成功 $successCount 个，失败 ${failedIds.length} 个', isError: failedIds.isNotEmpty);
      }
    } catch (e) {
      showTopSnackBar('批量删除失败: $e', isError: true);
    }
  }

  Future<void> renameConversation(Conversation conversation, String newName) async {
    if (newName.trim().isEmpty || newName == conversation.name) return;
    
    try {
      final int index = _conversations.indexWhere((c) => c.id == conversation.id);
      if (index != -1) {
        _conversations[index] = _conversations[index].copyWith(name: newName.trim());
        
        if (currentConversation?.id == conversation.id) {
          currentConversation = _conversations[index];
        }
      }
      
      await conversationApi.renameConversation(conversation.id, newName.trim());
      await fetchRemoteConversations();
      messagesStreamController.add(List.from(_currentMessages));
      
      showTopSnackBar('对话已重命名');
    } catch (e) {
      showTopSnackBar('重命名失败: $e', isError: true);
    }
  }
  
  void newConversation() {
    showTopSnackBar('已准备新建对话。请输入内容并发送，Dify将自动为您创建新对话。');
    
    currentConversation = null;
    _currentMessages = [];
    messagesStreamController.add(List.from(_currentMessages));
  }
  
  Future<void> refreshConversationsInBackground({
    required bool isUserScrolling,
    required bool hasTextInput,
  }) async {
    if (_isRefreshing || !allowSync) return;
    if (isUserScrolling || hasTextInput) return;
    
    try {
      _isRefreshing = true;
      
      final serverConversations = await conversationApi.fetchConversations();
      bool hasChanges = checkConversationsChanged(_conversations, serverConversations);
      
      if (hasChanges) {
        final currentId = currentConversation?.id;
        _conversations = serverConversations;
        
        if (currentId != null) {
          currentConversation = _conversations.firstWhereOrNull((c) => c.id == currentId) ?? 
                              (_conversations.isNotEmpty ? _conversations.first : null);
        }
        
        await ConversationCache.saveConversations(serverConversations);
      }
      
      _messageRefreshCounter++;
      
      if (currentConversation != null && allowSync && _messageRefreshCounter >= 3) {
        _messageRefreshCounter = 0;
        await fetchRemoteMessages(currentConversation!.id);
      }
    } catch (e) {
      // Silent handling of background refresh errors
    } finally {
      _isRefreshing = false;
    }
  }
  
  Future<void> manualRefresh() async {
    if (_isManualRefreshing || _isRefreshing) return;
    
    _isManualRefreshing = true;
    onStateChanged?.call();
    
    try {
      await fetchRemoteConversations();
      showTopSnackBar('刷新成功，获取到 ${_conversations.length} 个对话');
    } catch (e) {
      showTopSnackBar('刷新失败: $e', isError: true);
    } finally {
      _isManualRefreshing = false;
      onStateChanged?.call();
    }
  }
  
  bool checkConversationsChanged(List<Conversation> local, List<Conversation> remote) {
    if (local.length != remote.length) return true;
    
    final localMap = {for (var c in local) c.id: c};
    
    for (var remoteConv in remote) {
      final localConv = localMap[remoteConv.id];
      
      if (localConv == null || 
          localConv.name != remoteConv.name || 
          localConv.updatedAt.millisecondsSinceEpoch != remoteConv.updatedAt.millisecondsSinceEpoch) {
        return true;
      }
    }
    
    return false;
  }
  
  bool checkMessagesChanged(List<Message> oldMessages, List<Message> newMessages) {
    if (oldMessages.length != newMessages.length) {
      return true;
    }
    
    final oldMap = {for (var msg in oldMessages) msg.id: msg};
    
    for (var newMsg in newMessages) {
      final oldMsg = oldMap[newMsg.id];
      
      if (oldMsg == null) {
        return true;
      }
      
      if (oldMsg.query != newMsg.query || oldMsg.answer != newMsg.answer) {
        return true;
      }
      
      final oldFiles = oldMsg.messageFiles ?? [];
      final newFiles = newMsg.messageFiles ?? [];
      
      if (oldFiles.length != newFiles.length) {
        return true;
      }
      
      if (oldFiles.isNotEmpty) {
        final oldFileIds = oldFiles.map((f) => f.id).toSet();
        final newFileIds = newFiles.map((f) => f.id).toSet();
        if (!oldFileIds.containsAll(newFileIds) || !newFileIds.containsAll(oldFileIds)) {
          return true;
        }
      }
    }
    
    return false;
  }
  
  Future<void> _saveCurrentConversationId(String conversationId) async {
    try {
      final currentSettings = await SettingsManager.loadFromPrefs();
      currentSettings.updateSettings(
        currentConversationId: conversationId,
      );
      await currentSettings.saveToPrefs();
    } catch (e) {
      // Save current conversation ID failed, doesn't affect main functionality
    }
  }
}