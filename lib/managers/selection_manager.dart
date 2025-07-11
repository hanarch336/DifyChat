import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dify/models/message.dart';

/// 消息选择管理器
/// 
/// 用于处理多选模式下的消息选择、复制和删除等功能
class SelectionManager {
  // 选择状态
  bool _isSelectionMode = false;
  final Set<String> _selectedMessageIds = <String>{};
  
  // 状态变化回调
  VoidCallback? onStateChanged;
  
  // 获取当前是否处于选择模式
  bool get isSelectionMode => _isSelectionMode;
  
  // 获取已选择的消息ID集合
  Set<String> get selectedMessageIds => _selectedMessageIds;
  
  // 获取已选择的消息数量
  int get selectedCount => _selectedMessageIds.length;
  
  // 进入多选模式
  // 进入选择模式
  void enterSelectionMode() {
    _isSelectionMode = true;
    onStateChanged?.call();
  }
  
  // 退出选择模式
  void exitSelectionMode() {
    _isSelectionMode = false;
    _selectedMessageIds.clear();
    onStateChanged?.call();
  }
  
  // 处理消息选择状态变化
  void handleMessageSelection(String messageId, bool isSelected) {
    if (isSelected) {
      _selectedMessageIds.add(messageId);
    } else {
      _selectedMessageIds.remove(messageId);
    }
    onStateChanged?.call();
  }
  
  // 检查消息是否被选中
  bool isMessageSelected(String messageId) {
    return _selectedMessageIds.contains(messageId);
  }
  
  // 切换消息选择状态
  void toggleMessageSelection(String messageId) {
    if (_selectedMessageIds.contains(messageId)) {
      _selectedMessageIds.remove(messageId);
    } else {
      _selectedMessageIds.add(messageId);
    }
    onStateChanged?.call();
  }
  
  // 复制选中的消息
  void copySelectedMessages(List<Message> allMessages, BuildContext context) {
    if (_selectedMessageIds.isEmpty) return;
    
    final messages = allMessages
        .where((msg) => _selectedMessageIds.contains(msg.id))
        .toList();
    
    if (messages.isEmpty) return;
    
    final buffer = StringBuffer();
    for (final message in messages) {
      final sender = message.isUser ? '用户: ' : 'AI: ';
      final content = message.isUser ? message.query : message.answer;
      if (content != null && content.isNotEmpty) {
        buffer.writeln('$sender$content');
        buffer.writeln();
      }
    }
    
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制选中的消息')),
    );
    
    exitSelectionMode();
  }
  
  // 删除选中的消息（预留，未实现实际删除功能）
  void deleteSelectedMessages(BuildContext context) {
    if (_selectedMessageIds.isEmpty) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('删除功能尚未实现')),
    );
    
    exitSelectionMode();
  }
}