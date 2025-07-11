import 'dart:io';
import 'package:mime/mime.dart';

class FileUtils {
  /// 根据文件扩展名判断文件类型
  static String getFileType(String extension) {
    const imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'svg'];
    const audioExtensions = ['mp3', 'wav', 'aac', 'ogg', 'm4a', 'flac'];
    const videoExtensions = ['mp4', 'avi', 'mov', 'wmv', 'flv', 'mkv'];
    const documentExtensions = ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt'];
    
    final ext = extension.toLowerCase();
    
    if (imageExtensions.contains(ext)) {
      return 'image';
    } else if (audioExtensions.contains(ext)) {
      return 'audio';
    } else if (videoExtensions.contains(ext)) {
      return 'video';
    } else if (documentExtensions.contains(ext)) {
      return 'document';
    } else {
      return 'other';
    }
  }
  
  /// 根据文件路径获取MIME类型
  static String? getMimeType(String filePath) {
    return lookupMimeType(filePath);
  }
  
  /// 格式化文件大小
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
  
  /// 获取文件大小
  static int getFileSize(String filePath) {
    try {
      final file = File(filePath);
      return file.lengthSync();
    } catch (e) {
      return 0;
    }
  }
  
  /// 检查文件是否存在
  static bool fileExists(String filePath) {
    try {
      return File(filePath).existsSync();
    } catch (e) {
      return false;
    }
  }
  
  /// 获取文件名（不包含路径）
  static String getFileName(String filePath) {
    return filePath.split(Platform.pathSeparator).last;
  }
  
  /// 获取文件扩展名
  static String getFileExtension(String filePath) {
    final fileName = getFileName(filePath);
    final lastDotIndex = fileName.lastIndexOf('.');
    if (lastDotIndex != -1 && lastDotIndex < fileName.length - 1) {
      return fileName.substring(lastDotIndex + 1);
    }
    return '';
  }
  
  /// 检查是否为图片文件
  static bool isImageFile(String filePath) {
    return getFileType(getFileExtension(filePath)) == 'image';
  }
  
  /// 检查是否为音频文件
  static bool isAudioFile(String filePath) {
    return getFileType(getFileExtension(filePath)) == 'audio';
  }
  
  /// 检查是否为视频文件
  static bool isVideoFile(String filePath) {
    return getFileType(getFileExtension(filePath)) == 'video';
  }
  
  /// 检查是否为文档文件
  static bool isDocumentFile(String filePath) {
    return getFileType(getFileExtension(filePath)) == 'document';
  }
}