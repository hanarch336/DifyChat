import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';
import 'package:flutter_dify/models/conversation.dart';
import 'package:flutter_dify/models/message.dart';
import 'package:flutter_dify/services/conversation_api.dart';
import 'package:flutter_dify/services/conversation_cache.dart';

class ChatUploadFile {
  final String path;
  final String name;
  final String type;
  bool isUploading = false;
  bool isUploaded = false;
  String? uploadFileId;
  String? errorMessage;

  ChatUploadFile({required this.path, required this.name, required this.type});
  
  bool get isImage => type == 'image';
  bool get isDocument => type == 'document';
  bool get isAudio => type == 'audio';
  bool get isVideo => type == 'video';
  
  String get iconName {
    switch (type) {
      case 'image':
        return 'image';
      case 'document':
        return 'description';
      case 'audio':
        return 'audio_file';
      case 'video':
        return 'video_file';
      default:
        return 'insert_drive_file';
    }
  }
  
  Map<String, dynamic> toApiFormat() {
    return {
      'type': type,
      'transfer_method': 'local_file',
      'upload_file_id': uploadFileId,
    };
  }
}

class ChatMessageHandler {
  ConversationApi conversationApi;
  final StreamController<List<Message>> messagesStreamController;
  final Function(String, {bool isError}) showTopSnackBar;
  final Function(String)? onNewConversationCreated;
  
  bool _isMessageSending = false;
  bool get isMessageSending => _isMessageSending;
  
  ChatMessageHandler({
    required this.conversationApi,
    required this.messagesStreamController,
    required this.showTopSnackBar,

    this.onNewConversationCreated,
  });
  
  void updateApiClient(ConversationApi newApiClient) {
    conversationApi = newApiClient;
  }
  
  void setBackgroundCheckCallback(bool Function() callback) {
    // Message handler no longer needs background status check
  }
  Future<void> sendMessage({
    required List<Message> currentMessages,
    required String messageText,
    required List<ChatUploadFile> uploadFiles,
    required Conversation? currentConversation,
    required Function(List<Message>) updateMessages,
    required Function(bool) setAllowSync,
  }) async {
    if (messageText.isEmpty && uploadFiles.isEmpty) return;
    
    if (_isMessageSending) return;

    if (uploadFiles.any((file) => file.isUploading)) {
      showTopSnackBar('请等待文件上传完成', isError: true);
      return;
    }
    
    _isMessageSending = true;
    final String finalMessageText = messageText.isEmpty && uploadFiles.isNotEmpty ? "查看附件" : messageText;
    
    List<Map<String, dynamic>> fileData = [];
    List<MessageFile> messageFiles = [];
    
    if (uploadFiles.isNotEmpty) {
      for (var file in uploadFiles) {
        if (file.isUploaded && file.uploadFileId != null) {
          fileData.add({
            'type': file.type,
            'transfer_method': 'local_file',
            'upload_file_id': file.uploadFileId,
          });
          
          messageFiles.add(MessageFile(
            id: file.uploadFileId ?? '',
            type: file.type,
            url: file.path,
            belongsTo: 'user',
            filename: file.name,
          ));
        }
      }
    }
    
    final userMessageId = DateTime.now().millisecondsSinceEpoch.toString();
    final aiMessageId = '$userMessageId-ai';
    
    final userMessage = Message(
      id: userMessageId,
      conversationId: currentConversation?.id ?? '',
      query: finalMessageText,
      answer: finalMessageText,
      isUser: true,
      createdAt: DateTime.now(),
      status: MessageStatus.complete,
      messageFiles: messageFiles.isNotEmpty ? messageFiles : null,
    );
    
    final aiMessage = Message(
      id: aiMessageId,
      conversationId: currentConversation?.id ?? '',
      query: '',
      answer: '',
      isUser: false,
      createdAt: DateTime.now(),
      status: MessageStatus.loading,
    );
    
    List<Message> updatedMessages = [...currentMessages, userMessage, aiMessage];
    updateMessages(updatedMessages);
    messagesStreamController.add(List.from(updatedMessages));
    
    if (currentConversation != null) {
      ConversationCache.saveMessages(currentConversation.id, updatedMessages);
    }
    
    final conversationIdToSend = currentConversation?.id;
    setAllowSync(false);
    
    try {
      final stream = fileData.isNotEmpty
          ? conversationApi.sendChatMessageWithFiles(
              finalMessageText,
              conversationId: conversationIdToSend,
              inputs: {},
              files: fileData,
            )
          : conversationApi.sendChatMessage(
              finalMessageText,
              conversationId: conversationIdToSend,
              inputs: {},
            );

      String accumulatedAnswer = '';
      await for (var eventData in stream) {
        switch (eventData['event']) {
          case 'message':
            final String? answerChunk = eventData['answer'];
            if (answerChunk != null) {
              accumulatedAnswer += answerChunk;
              final index = updatedMessages.indexWhere((msg) => msg.id == aiMessageId);
              if (index != -1) {
                final updatedMessage = updatedMessages[index].copyWith(
                  answer: accumulatedAnswer,
                  status: MessageStatus.loading,
                );
                updatedMessages[index] = updatedMessage;
              }
              
              // 立即更新UI，确保Markdown实时渲染
              updateMessages(updatedMessages);
              messagesStreamController.add(List.from(updatedMessages));
              
              // 几乎无延迟，但保留最小延迟以避免UI阻塞
              await Future.delayed(const Duration(microseconds: 1));
            }
            break;
          case 'message_file':
            // 处理AI返回的文件
            final messageFile = MessageFile(
              id: eventData['id'] ?? '',
              type: eventData['type'] ?? '',
              url: eventData['url'] ?? '',
              belongsTo: eventData['belongs_to'] ?? 'assistant',
              previewUrl: eventData['preview_url'],
              filename: eventData['filename'],
            );
            
            final index = updatedMessages.indexWhere((msg) => msg.id == aiMessageId);
            if (index != -1) {
              final currentFiles = updatedMessages[index].messageFiles ?? [];
              final updatedMessage = updatedMessages[index].copyWith(
                messageFiles: [...currentFiles, messageFile],
              );
              updatedMessages[index] = updatedMessage;
              
              updateMessages(updatedMessages);
              messagesStreamController.add(List.from(updatedMessages));
            }
            break;
          case 'message_end':
            final String? returnedConversationId = eventData['conversation_id'];
            final index = updatedMessages.indexWhere((msg) => msg.id == aiMessageId);
            if (index != -1) {
              updatedMessages[index] = updatedMessages[index].copyWith(
                status: MessageStatus.complete,
                conversationId: returnedConversationId ?? updatedMessages[index].conversationId,
                id: eventData['message_id'] ?? aiMessageId,
              );
              // Also update the user message's conversationId if it's a new conversation
              final userMessageIndex = updatedMessages.indexWhere((msg) => msg.id == userMessageId);
              if (userMessageIndex != -1) {
                updatedMessages[userMessageIndex] = updatedMessages[userMessageIndex].copyWith(
                  conversationId: returnedConversationId ?? updatedMessages[userMessageIndex].conversationId,
                );
              }
            }
            updateMessages(updatedMessages);
            messagesStreamController.add(List.from(updatedMessages));

            if (returnedConversationId != null && currentConversation == null && onNewConversationCreated != null) {
              onNewConversationCreated!(returnedConversationId);
            }

            final conversationId = returnedConversationId ?? currentConversation?.id;
            if (conversationId != null && conversationId.isNotEmpty) {
              ConversationCache.saveMessages(conversationId, updatedMessages);
            }
            
            setAllowSync(true);
            _isMessageSending = false;
            break;
          case 'error':
            final String errorMessage = eventData['message'] ?? '未知流式错误';
            final index = updatedMessages.indexWhere((msg) => msg.id == aiMessageId);
            if (index != -1) {
              updatedMessages[index] = updatedMessages[index].copyWith(
                answer: '服务器错误: $errorMessage',
                status: MessageStatus.error,
              );
            }
            updateMessages(updatedMessages);
            messagesStreamController.add(List.from(updatedMessages));
            
            if (currentConversation != null) {
              ConversationCache.saveMessages(currentConversation.id, updatedMessages);
            }
            
            setAllowSync(true);
            _isMessageSending = false;
            break;
        }
      }
    } catch (e) {
      final index = updatedMessages.indexWhere((msg) => msg.id == aiMessageId);
      if (index != -1) {
        updatedMessages[index] = updatedMessages[index].copyWith(
          answer: '连接或处理异常: $e',
          status: MessageStatus.error,
        );
      }
      updateMessages(updatedMessages);
      messagesStreamController.add(List.from(updatedMessages));
      
      if (currentConversation != null) {
        ConversationCache.saveMessages(currentConversation.id, updatedMessages);
      }
      
      setAllowSync(true);
      _isMessageSending = false;
    } finally {
      // 使用非阻塞方式更新缓存
      if (currentConversation != null) {
        ConversationCache.saveMessages(currentConversation.id, updatedMessages);
      }
      
      setAllowSync(true);
      _isMessageSending = false;
    }
  }

  Future<void> retryMessage({
    required Message message,
    required List<Message> currentMessages,
    required Function(List<Message>) updateMessages,
    required Function(bool) setAllowSync,
  }) async {
    if (message.query == null || message.query!.isEmpty) return;
    
    final index = currentMessages.indexWhere((m) => m.id == message.id);
    if (index == -1) return;

    List<Message> updatedMessages = List.from(currentMessages);
    updatedMessages[index] = message.copyWith(
      status: MessageStatus.loading,
      answer: '',
    );
    updateMessages(updatedMessages);
    messagesStreamController.add(List.from(updatedMessages));
    
    setAllowSync(false);
    
    if (message.conversationId.isNotEmpty) {
      ConversationCache.saveMessages(message.conversationId, updatedMessages);
    }

    try {
      final stream = conversationApi.sendChatMessage(
        message.query!,
        conversationId: message.conversationId,
        inputs: {},
      );

      await for (var eventData in stream) {
        switch (eventData['event']) {
          case 'message':
            final String? answerChunk = eventData['answer'];
            if (answerChunk != null) {
              final updatedMessage = updatedMessages[index].copyWith(
                answer: (updatedMessages[index].answer ?? '') + answerChunk,
                status: MessageStatus.loading,
              );
              updatedMessages[index] = updatedMessage;
              
              updateMessages(updatedMessages);
              messagesStreamController.add(List.from(updatedMessages));
              

            }
            break;
          case 'message_end':
            final String? returnedConversationId = eventData['conversation_id'];
            updatedMessages[index] = updatedMessages[index].copyWith(
              status: MessageStatus.complete,
              conversationId: returnedConversationId ?? updatedMessages[index].conversationId,
              id: eventData['message_id'] ?? updatedMessages[index].id,
            );
            
            updateMessages(updatedMessages);
            messagesStreamController.add(List.from(updatedMessages));

            final conversationId = returnedConversationId ?? message.conversationId;
            if (conversationId.isNotEmpty) {
              ConversationCache.saveMessages(conversationId, updatedMessages);
            }
            
            setAllowSync(true);
            _isMessageSending = false;
            break;
          case 'error':
            final String errorMessage = eventData['message'] ?? '未知流式错误';
            updatedMessages[index] = updatedMessages[index].copyWith(
              answer: '服务器错误: $errorMessage',
              status: MessageStatus.error,
            );
            
            updateMessages(updatedMessages);
            messagesStreamController.add(List.from(updatedMessages));
            
            if (message.conversationId.isNotEmpty) {
              ConversationCache.saveMessages(message.conversationId, updatedMessages);
            }
            
            setAllowSync(true);
            break;
        }
      }
    } catch (e) {
      updatedMessages[index] = updatedMessages[index].copyWith(
        answer: '重试失败: $e',
        status: MessageStatus.error,
      );
      
      updateMessages(updatedMessages);
      messagesStreamController.add(List.from(updatedMessages));
      
      if (message.conversationId.isNotEmpty) {
        ConversationCache.saveMessages(message.conversationId, updatedMessages);
      }
      
      setAllowSync(true);
    }
  }

  Future<void> uploadFile({
    required ChatUploadFile file,
    required Function(ChatUploadFile) updateFile,
    required Function(bool) setIsUploadingFiles,
    required BuildContext context,
  }) async {
    try {
      updateFile(file..errorMessage = null);
      setIsUploadingFiles(true);
      
      final response = await conversationApi.uploadFile(File(file.path));
      
      updateFile(file..isUploading = false
                    ..isUploaded = true
                    ..uploadFileId = response['id']);
      
      setIsUploadingFiles(false);
      
    } catch (e) {
      updateFile(file..isUploading = false
                    ..isUploaded = false
                    ..errorMessage = e.toString());
      
      setIsUploadingFiles(false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('文件上传失败: ${file.name}, 错误: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<List<ChatUploadFile>> pickImage() async {
    List<ChatUploadFile> result = [];
    
    final pickerResult = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );
    
    if (pickerResult != null && pickerResult.files.isNotEmpty) {
      for (var file in pickerResult.files) {
        if (file.path != null) {
          result.add(ChatUploadFile(
            path: file.path!,
            name: file.name,
            type: 'image',
          ));
        }
      }
    }
    
    return result;
  }
  
  Future<List<ChatUploadFile>> pickFile() async {
    List<ChatUploadFile> result = [];
    
    final pickerResult = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: true,
    );
    
    if (pickerResult != null && pickerResult.files.isNotEmpty) {
      for (var file in pickerResult.files) {
        if (file.path != null) {
          String fileType = 'document';
          final mimeType = lookupMimeType(file.path!) ?? 'application/octet-stream';
          if (mimeType.startsWith('image/')) {
            fileType = 'image';
          } else if (mimeType.startsWith('audio/')) {
            fileType = 'audio';
          } else if (mimeType.startsWith('video/')) {
            fileType = 'video';
          }
          
          result.add(ChatUploadFile(
            path: file.path!,
            name: file.name,
            type: fileType,
          ));
        }
      }
    }
    
    return result;
  }
  

}