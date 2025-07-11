import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';
import '../models/conversation.dart';
import '../models/message.dart';

class ConversationApi {
  final String baseUrl;
  final String apiKey;
  final String userId;
  final http.Client _client;

  ConversationApi({
    required this.baseUrl,
    required this.apiKey,
    required this.userId,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<List<Conversation>> fetchConversations() async {
    final uri = Uri.parse('$baseUrl/conversations?user=$userId');
    final headers = {'Authorization': 'Bearer $apiKey'};
    try {
      final response = await _client.get(
        uri,
        headers: headers,
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['data'] as List)
          .map((e) => Conversation.fromJson(e))
          .toList();
    } else {
        throw Exception('获取对话列表失败: ${response.statusCode} - ${response.body}');
    }
    } catch (e) {

      throw Exception('获取对话列表时发生异常: $e');
    }
  }

  Future<List<Message>> fetchMessages(String conversationId) async {
    final uri = Uri.parse('$baseUrl/messages?conversation_id=$conversationId&user=$userId');
    final headers = {'Authorization': 'Bearer $apiKey'};
    try {
      final response = await _client.get(
        uri,
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        return (data['data'] as List)
            .map((e) => Message.fromJson(e))
            .toList();
      } else {
        throw Exception('获取消息列表失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {

      throw Exception('获取消息列表时发生异常: $e');
    }
  }

  Stream<Map<String, dynamic>> sendChatMessage(
    String query, {
    String? conversationId,
    Map<String, dynamic>? inputs,
  }) async* {
    final Map<String, dynamic> body = {
      'query': query,
      'user': userId,
      'response_mode': 'streaming',
      'inputs': inputs ?? {},
      'auto_generate_name': true,
    };
    if (conversationId != null) {
      body['conversation_id'] = conversationId;
    }

    final uri = Uri.parse('$baseUrl/chat-messages');
    final headers = {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
      'Accept': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive',
    };

    try {
      final request = http.Request('POST', uri)
        ..headers.addAll(headers)
        ..body = json.encode(body);

      final streamedResponse = await _client.send(request);

      if (streamedResponse.statusCode == 200) {
        await for (var chunk in streamedResponse.stream.transform(utf8.decoder).transform(const LineSplitter())) {
          if (chunk.startsWith('data:')) {
            final dataString = chunk.substring(5).trim();
            if (dataString.isNotEmpty) {
              try {
                final eventData = json.decode(dataString) as Map<String, dynamic>;
                yield eventData;
              } catch (e) {

              }
            }
          }
        }
      } else {
        final errorBody = await streamedResponse.stream.bytesToString();

        throw Exception('发送消息（流式）失败: ${streamedResponse.statusCode} - $errorBody');
      }
    } catch (e) {

      throw Exception('发送消息（流式）时发生异常: $e');
    }
  }

  Future<void> deleteConversation(String id) async {
    final uri = Uri.parse('$baseUrl/conversations/$id');
    final headers = {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    };
    final body = {'user': userId};
    final response = await _client.delete(
      uri,
      headers: headers,
      body: json.encode(body),
    );
    if (response.statusCode != 204) {
      throw Exception('删除对话失败: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> renameConversation(String id, String newName) async {
    final uri = Uri.parse('$baseUrl/conversations/$id/name');
    final headers = {
      'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
    };
    final body = {'name': newName, 'user': userId};
    final response = await _client.post(
      uri,
      headers: headers,
      body: json.encode(body),
    );
    if (response.statusCode != 200) {
      throw Exception('重命名对话失败: ${response.statusCode} - ${response.body}');
    }
  }


  Future<Map<String, dynamic>> uploadFile(File file) async {

    final fileSize = await file.length();
    final fileSizeInMB = fileSize / (1024 * 1024);
    

    if (fileSizeInMB > 15) {
      throw Exception('文件大小超过限制 (${fileSizeInMB.toStringAsFixed(2)}MB)，最大允许15MB');
    }
    
    final uri = Uri.parse('$baseUrl/files/upload');
    
    try {

      return await _uploadFileBinary(file, uri);
    } catch (e) {

      throw Exception('文件上传失败: $e');
    }
  }
  

  Future<Map<String, dynamic>> _uploadFileBinary(File file, Uri uri) async {
    final fileName = path.basename(file.path);
    final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
    

    final bytes = await file.readAsBytes();
    

    final boundary = '----DifyFileUploadBoundary${DateTime.now().millisecondsSinceEpoch}';
    

    final List<int> body = [];
    

    body.addAll(utf8.encode('--$boundary\r\n'));
    body.addAll(utf8.encode('Content-Disposition: form-data; name="user"\r\n\r\n'));
    body.addAll(utf8.encode('$userId\r\n'));
    

    body.addAll(utf8.encode('--$boundary\r\n'));
    body.addAll(utf8.encode('Content-Disposition: form-data; name="file"; filename="$fileName"\r\n'));
    body.addAll(utf8.encode('Content-Type: $mimeType\r\n\r\n'));
    body.addAll(bytes);
    body.addAll(utf8.encode('\r\n'));
    

    body.addAll(utf8.encode('--$boundary--\r\n'));
    

    final headers = {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'multipart/form-data; boundary=$boundary',
      'Content-Length': body.length.toString(),
    };
    

    final response = await _client.post(
      uri,
      headers: headers,
      body: body,
    );
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = json.decode(response.body);
      if (responseData['id'] == null) {
        throw Exception('文件上传成功但返回数据缺少ID字段: ${response.body}');
      }
      return responseData;
    } else {
      throw Exception('文件上传失败: ${response.statusCode} - ${response.body}');
    }
  }
  

  Stream<Map<String, dynamic>> sendChatMessageWithFiles(
    String query, {
    String? conversationId,
    Map<String, dynamic>? inputs,
    List<Map<String, dynamic>>? files,
  }) async* {
    final Map<String, dynamic> body = {
      'query': query,
      'user': userId,
      'response_mode': 'streaming',
      'inputs': inputs ?? {},
    };
    
    if (conversationId != null) {
      body['conversation_id'] = conversationId;
    }
    
    if (files != null && files.isNotEmpty) {
      body['files'] = files;
    }

    final uri = Uri.parse('$baseUrl/chat-messages');
    final headers = {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
      'Accept': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive',
    };

    try {
      final request = http.Request('POST', uri)
        ..headers.addAll(headers)
        ..body = json.encode(body);

      final streamedResponse = await _client.send(request);

      if (streamedResponse.statusCode == 200) {
        await for (var chunk in streamedResponse.stream.transform(utf8.decoder).transform(const LineSplitter())) {
          if (chunk.startsWith('data:')) {
            final dataString = chunk.substring(5).trim();
            if (dataString.isNotEmpty) {
              try {
                final eventData = json.decode(dataString) as Map<String, dynamic>;
                yield eventData;
              } catch (e) {

              }
            }
          }
        }
      } else {
        final errorBody = await streamedResponse.stream.bytesToString();

        throw Exception('发送带文件消息（流式）失败: ${streamedResponse.statusCode} - $errorBody');
      }
    } catch (e) {

      throw Exception('发送带文件消息（流式）时发生异常: $e');
    }
  }


  Future<List<Message>> getMessages(String conversationId) async {
    try {
      final uri = Uri.parse('$baseUrl/messages?conversation_id=$conversationId&user=$userId');
      final headers = {'Authorization': 'Bearer $apiKey'};
      final response = await _client.get(
        uri,
        headers: headers,
      );

      final data = json.decode(response.body);
      final List<dynamic> messageData = data['data'];
      final List<Message> apiMessages = messageData.map((item) => Message.fromJson(item)).toList();
      
      final List<Message> processedMessages = [];
      for (var apiMsg in apiMessages) {

        if (apiMsg.query != null && apiMsg.query!.isNotEmpty) {
          final userMsg = Message(
            id: apiMsg.id,
            conversationId: apiMsg.conversationId,
            query: apiMsg.query,
            answer: apiMsg.query,
            isUser: true,
            createdAt: apiMsg.createdAt,
            status: MessageStatus.complete,
            messageFiles: apiMsg.messageFiles?.where((file) => file.belongsTo == 'user').toList(),
          );
          processedMessages.add(userMsg);
        }


        if (apiMsg.answer != null && apiMsg.answer!.isNotEmpty) {
          final aiMsg = Message(
            id: '${apiMsg.id}-ai',
            conversationId: apiMsg.conversationId,
            query: '',
            answer: apiMsg.answer,
            isUser: false,
            createdAt: apiMsg.createdAt,
            status: MessageStatus.complete,
            messageFiles: apiMsg.messageFiles?.where((file) => file.belongsTo == 'assistant').toList(),
          );
          processedMessages.add(aiMsg);
        }
      }


      processedMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      
      return processedMessages;
    } catch (e) {

      rethrow;
    }
  }
}