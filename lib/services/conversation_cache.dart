import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/conversation.dart';
import '../models/message.dart';

class ConversationCache {
  static const String cacheKey = 'conversation_list';
  static const String messagesCacheKeyPrefix = 'messages_';
  
  // 内存缓存
  static List<Conversation>? _cachedConversations;
  static final Map<String, List<Message>> _cachedMessages = {};

  static Future<void> saveConversations(List<Conversation> list) async {
    // 更新内存缓存
    _cachedConversations = List.from(list);
    
    final prefs = await SharedPreferences.getInstance();
    final jsonList = list.map((e) => e.toJson()).toList();
    await prefs.setString(cacheKey, json.encode(jsonList));
  }

  static Future<List<Conversation>> getConversations() async {
    // 如果内存缓存有数据，直接返回
    if (_cachedConversations != null) {
      return _cachedConversations!;
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(cacheKey); // 修正键名
      if (jsonString == null) return [];
      
      final jsonList = jsonDecode(jsonString) as List;
      _cachedConversations = jsonList.map((item) => Conversation.fromJson(item)).toList();
      return _cachedConversations!;
    } catch (e) {
      // 从缓存加载对话失败
      return [];
    }
  }

  static Future<List<Message>> getMessages(String conversationId) async {
    // 如果内存缓存有数据，直接返回
    if (_cachedMessages.containsKey(conversationId)) {
      return _cachedMessages[conversationId]!;
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('$messagesCacheKeyPrefix$conversationId');
      if (jsonString == null) return [];
      
      final jsonList = jsonDecode(jsonString) as List;
      final messages = jsonList.map((item) => Message.fromJson(item)).toList();
      
      // 更新内存缓存
      _cachedMessages[conversationId] = messages;
      
      return messages;
    } catch (e) {
      // 从缓存加载消息失败
      return [];
    }
  }
  
  // 保存单个对话的消息列表
  static Future<void> saveMessages(String conversationId, List<Message> messages) async {
    // 更新内存缓存
    _cachedMessages[conversationId] = List.from(messages);
    
    final prefs = await SharedPreferences.getInstance();
    
    // 将消息转换为JSON
    final jsonList = messages.map((message) => message.toJson()).toList();
    
    // 保存到本地存储
    await prefs.setString('$messagesCacheKeyPrefix$conversationId', json.encode(jsonList));
  }
  
  // 加载单个对话的消息列表
  static Future<List<Message>> loadMessages(String conversationId) async {
    // 如果内存缓存有数据，直接返回
    if (_cachedMessages.containsKey(conversationId)) {
      return _cachedMessages[conversationId]!;
    }
    
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('$messagesCacheKeyPrefix$conversationId');
    if (jsonStr == null) return [];
    
    try {
    final List data = json.decode(jsonStr);
      final messages = data.map((e) => Message.fromJson(e)).toList();
      
      // 更新内存缓存
      _cachedMessages[conversationId] = messages;
      
      return messages;
    } catch (e) {
      // 加载消息缓存失败
      return [];
    }
  }
  
  // 清除单个对话的消息缓存
  static Future<void> clearMessages(String conversationId) async {
    // 清除内存缓存
    _cachedMessages.remove(conversationId);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$messagesCacheKeyPrefix$conversationId');
  }
  
  // 清除所有对话的消息缓存
  static Future<void> clearAllMessages() async {
    // 清除内存缓存
    _cachedMessages.clear();
    
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    
    for (var key in keys) {
      if (key.startsWith(messagesCacheKeyPrefix)) {
        await prefs.remove(key);
      }
    }
  }
  
  // 预加载所有缓存数据到内存
  static Future<void> preloadCache() async {
    await getConversations();
    
    if (_cachedConversations != null && _cachedConversations!.isNotEmpty) {
      // 仅预加载第一个对话的消息
      if (_cachedConversations!.isNotEmpty) {
        await getMessages(_cachedConversations!.first.id);
      }
    }
  }
}