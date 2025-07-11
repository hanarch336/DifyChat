import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../models/message.dart';
import '../managers/message_handler.dart'; // 导入ChatUploadFile类型

// 文件附件预览组件（发送前）
class FileAttachmentPreview extends StatelessWidget {
  final List<ChatUploadFile> files;
  final Function(ChatUploadFile) onRemove;

  const FileAttachmentPreview({
    Key? key,
    required this.files,
    required this.onRemove,
  }) : super(key: key);

  static IconData _getFileIcon(String iconName) {
    switch (iconName) {
      case 'image':
        return Icons.image;
      case 'description':
        return Icons.description;
      case 'audio_file':
        return Icons.audio_file;
      case 'video_file':
        return Icons.video_file;
      default:
        return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 8),
            child: Text(
              '附件',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: files.length,
              itemBuilder: (context, index) {
                final file = files[index];
                return _buildFilePreviewItem(context, file);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilePreviewItem(BuildContext context, ChatUploadFile file) {
    return Container(
      width: file.isImage ? 90 : 150,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (file.isImage)
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    child: Image.file(
                      File(file.path),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 40),
                    ),
                  ),
                )
              else
                Expanded(
                  child: Center(
                    child: Icon(
                      _getFileIcon(file.iconName),
                      size: 40,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                ),
                child: Text(
                  file.name,
                  style: const TextStyle(fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (file.isUploading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          else if (file.errorMessage != null)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 30,
                  ),
                ),
              ),
            ),
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => onRemove(file),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 消息文件附件组件（发送后）
class MessageFileAttachment extends StatelessWidget {
  final List<MessageFile> files;
  final bool isUserMessage; // 添加参数标识是否为用户消息

  const MessageFileAttachment({
    Key? key,
    required this.files,
    this.isUserMessage = false, // 默认为AI消息
  }) : super(key: key);

  static IconData _getFileIcon(String iconName) {
    switch (iconName) {
      case 'image':
        return Icons.image;
      case 'description':
        return Icons.description;
      case 'audio_file':
        return Icons.audio_file;
      case 'video_file':
        return Icons.video_file;
      default:
        return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft, // 根据消息发送者调整对齐方式
      child: SizedBox(
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: files.length,
          shrinkWrap: true, // 添加此属性使ListView宽度适应内容
          itemBuilder: (context, index) {
            final file = files[index];
            return _buildFileItem(context, file);
          },
        ),
      ),
    );
  }

  // 下载文件
  Future<void> _downloadFile(BuildContext context, MessageFile file) async {
    try {
      final url = file.url;
      if (await canLaunchUrlString(url)) {
        await launchUrlString(url);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('正在下载: ${file.displayFilename}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('无法打开下载链接'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('下载失败: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildFileItem(BuildContext context, MessageFile file) {
    // 获取文件名 - 使用displayFilename方法
    String fileName = file.displayFilename;
    
    // 检查URL是否为本地文件路径
    bool isLocalFile = file.url.startsWith('/') || file.url.startsWith('file:') || file.url.contains(':\\');
    
    // 为整个容器添加GestureDetector，使整个气泡可点击
    return GestureDetector(
      onTap: () {
        // 如果是图片，显示预览，否则直接下载
        if (file.isImage) {
          showDialog(
            context: context,
            barrierColor: Colors.black87,
            builder: (context) => Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.zero,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 图片可滚动和缩放
                  InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 3.0,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: isLocalFile 
                              ? Hero(
                                  tag: 'image_${file.id}',
                                  child: Image.file(
                                    File(file.url),
                                    errorBuilder: (context, error, stackTrace) {
                                      // 本地图片加载错误
                                      return Container(
                                        color: Colors.black54,
                                        child: const Center(
                                          child: Icon(Icons.broken_image, size: 40, color: Colors.white),
                                        ),
                                      );
                                    },
                                  ),
                                )
                              : Hero(
                                  tag: 'image_${file.id}',
                                  child: Image.network(
                                    file.originalUrl, // 使用原图URL而不是缩略图
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        color: Colors.transparent,
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress.expectedTotalBytes != null
                                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                : null,
                                            color: Colors.white,
                                          ),
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      // 网络图片加载错误
                                      return Container(
                                        color: Colors.transparent,
                                        child: const Center(
                                          child: Icon(Icons.broken_image, size: 40, color: Colors.white),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // 底部文件名显示
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                        ),
                      ),
                      child: Text(
                        fileName,
                        style: const TextStyle(fontSize: 16, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  // 关闭按钮
                  Positioned(
                    top: 40,
                    right: 20,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 24,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  // 下载按钮
                  Positioned(
                    top: 40,
                    left: 20,
                    child: GestureDetector(
                      onTap: () {
                        _downloadFile(context, file);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.download,
                          size: 24,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          // 非图片文件直接下载
          _downloadFile(context, file);
        }
      },
      child: Container(
        width: file.isImage ? 90 : 150,  // 图片保持方形，文档改为长方形
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (file.isImage)
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  child: isLocalFile 
                    ? Hero(
                        tag: 'image_${file.id}',
                        child: Image.file(
                          File(file.url),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            // 本地缩略图加载错误
                            return const Icon(Icons.broken_image, size: 40);
                          },
                        ),
                      )
                    : Hero(
                        tag: 'image_${file.id}',
                        child: Image.network(
                          file.displayUrl, // 缩略图使用displayUrl
                          fit: BoxFit.cover,
                          width: double.infinity,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                    : null,
                                strokeWidth: 2,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            // 网络缩略图加载错误
                            return const Icon(Icons.broken_image, size: 40);
                          },
                          cacheWidth: 200,
                          cacheHeight: 200,
                          gaplessPlayback: true,
                        ),
                      ),
                ),
              )
            else
              Expanded(
                child: Center(
                  child: Icon(
                    _getFileIcon(file.iconName),
                    size: 40,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
              ),
              child: Text(
                file.isImage ? '图片' : fileName,
                style: const TextStyle(fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}