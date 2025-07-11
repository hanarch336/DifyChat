enum MessageStatus {
  sending,
  loading,
  complete,
  error,
}

class Message {
  final String id;
  final String conversationId;
  final String? query;
  final String? answer;
  final bool isUser;
  final DateTime createdAt;
  final List<MessageFile>? messageFiles;
  final MessageStatus status;

  Message({
    required this.id,
    required this.conversationId,
    this.query,
    this.answer,
    required this.isUser,
    required this.createdAt,
    this.messageFiles,
    this.status = MessageStatus.complete,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    final bool isUser = json['query'] != null && json['query'].isNotEmpty;
    return Message(
      id: json['id'],
      conversationId: json['conversation_id'],
      query: json['query'],
      answer: json['answer'],
      isUser: isUser,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at'] * 1000),
      messageFiles: json['message_files'] != null
          ? (json['message_files'] as List)
              .map((e) => MessageFile.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      status: MessageStatus.complete,
    );
  }

  String get text => isUser ? (query ?? '') : (answer ?? '');

  Message copyWith({
    String? id,
    String? conversationId,
    String? query,
    String? answer,
    bool? isUser,
    DateTime? createdAt,
    List<MessageFile>? messageFiles,
    MessageStatus? status,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      query: query ?? this.query,
      answer: answer ?? this.answer,
      isUser: isUser ?? this.isUser,
      createdAt: createdAt ?? this.createdAt,
      messageFiles: messageFiles ?? this.messageFiles,
      status: status ?? this.status,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'query': query,
      'answer': answer,
      'is_user': isUser,
      'created_at': createdAt.millisecondsSinceEpoch ~/ 1000,
      'status': status.index,
      'message_files': messageFiles?.map((file) => file.toJson()).toList(),
    };
  }
}

class MessageFile {
  final String id;
  final String type;
  final String url;
  final String belongsTo;
  final String? previewUrl;
  final String? filename;

  MessageFile({
    required this.id,
    required this.type,
    required this.url,
    required this.belongsTo,
    this.previewUrl,
    this.filename,
  });

  factory MessageFile.fromJson(Map<String, dynamic> json) {
    return MessageFile(
      id: json['id'],
      type: json['type'],
      url: json['url'],
      belongsTo: json['belongs_to'],
      previewUrl: json['preview_url'],
      filename: json['filename'],
    );
  }
  
  String get displayUrl => previewUrl ?? url;
  
  String get originalUrl => url;
  
  String get displayFilename {
    if (filename != null && filename!.isNotEmpty) {
      return filename!;
    }
    
    String extractedName = 'unknown';
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        extractedName = pathSegments.last;
        if (extractedName.contains('?')) {
          extractedName = extractedName.substring(0, extractedName.indexOf('?'));
        }
      }
    } catch (e) {
      extractedName = url.split('/').last;
      if (extractedName.contains('?')) {
        extractedName = extractedName.substring(0, extractedName.indexOf('?'));
      }
    }
    
    return extractedName;
  }
  
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
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'url': url,
      'belongs_to': belongsTo,
      'preview_url': previewUrl,
      'filename': filename,
    };
  }
}

class UploadFile {
  final String path;
  final String name;
  final String type;
  String? uploadFileId;
  bool isUploading = false;
  bool isUploaded = false;
  String? errorMessage;

  UploadFile({
    required this.path,
    required this.name,
    required this.type,
  });
  
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