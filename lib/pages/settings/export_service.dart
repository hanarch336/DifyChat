import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../services/conversation_cache.dart';
import '../../managers/conversation_manager.dart';

class ExportService {
  static Future<void> exportAllConversations(BuildContext context, ConversationManager conversationManager) async {
    try {

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('正在导出对话数据...'),
            ],
          ),
        ),
      );


      final conversations = await ConversationCache.getConversations();
      

      final exportData = {
        'export_info': {
          'version': '1.0',
          'export_time': DateTime.now().toIso8601String(),
          'total_conversations': conversations.length,
        },
        'conversations': [],
      };


      for (final conversation in conversations) {
        final messages = await ConversationCache.getMessages(conversation.id);
        
        final conversationData = {
          'conversation_info': conversation.toJson(),
          'messages': messages.map((message) => message.toJson()).toList(),
          'message_count': messages.length,
        };
        
        (exportData['conversations'] as List).add(conversationData);
      }


      Navigator.of(context).pop();


      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: '保存对话数据',
        fileName: 'conversations_export_${DateTime.now().millisecondsSinceEpoch}.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: utf8.encode(jsonString),
      );

      if (outputFile != null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('导出成功！共导出 ${conversations.length} 个对话'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导出失败：$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  static Future<void> showExportDialog(BuildContext context, ConversationManager conversationManager) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('导出对话数据'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('将导出所有对话数据为JSON格式文件，包括：'),
              SizedBox(height: 8),
              Text('• 对话列表信息'),
              Text('• 每个对话的所有消息'),
              Text('• 消息附件信息'),
              Text('• 导出时间和统计信息'),
              SizedBox(height: 16),
              Text(
                '注意：导出的文件可能较大，请确保有足够的存储空间。',
                style: TextStyle(color: Colors.orange),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('开始导出'),
              onPressed: () {
                Navigator.of(context).pop();
                exportAllConversations(context, conversationManager);
              },
            ),
          ],
        );
      },
    );
  }
}