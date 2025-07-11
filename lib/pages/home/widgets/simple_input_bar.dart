import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dify/pages/home/controllers/home_controller.dart';
import 'package:flutter_dify/widgets/file_attachment_widget.dart';
import 'package:flutter_dify/utils/file_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

class SimpleInputBar extends StatefulWidget {
  final HomeController controller;

  const SimpleInputBar({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  State<SimpleInputBar> createState() => _SimpleInputBarState();
}

class _SimpleInputBarState extends State<SimpleInputBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          if (widget.controller.uploadFiles.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: FileAttachmentPreview(
                files: widget.controller.uploadFiles,
                onRemove: (file) {
                  widget.controller.uploadFiles.remove(file);
                  widget.controller.updateUI();
                },
              ),
            ),

          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24.0),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                _buildFileButton(context),
                _buildImageButton(context),
                const SizedBox(width: 8),
                _buildTextField(context),
                const SizedBox(width: 8),
                _buildSendButton(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileButton(BuildContext context) {
    return IconButton(
      onPressed: () => _pickFile(context),
      icon: Icon(
        Icons.attach_file,
        color: widget.controller.uploadFiles.any((f) => f.type != 'image')
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.primary,
      ),
      tooltip: '添加文件',
    );
  }

  Widget _buildImageButton(BuildContext context) {
    return IconButton(
      onPressed: () => _pickImage(context),
      icon: Icon(
        Icons.image,
        color: widget.controller.uploadFiles.any((f) => f.type == 'image')
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.primary,
      ),
      tooltip: '添加图片',
    );
  }

  Widget _buildTextField(BuildContext context) {
    return Expanded(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxHeight: 120,
        ),
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.enter, control: true): () {
              _sendMessage();
            },
          },
          child: TextField(
              controller: widget.controller.textController,
              focusNode: widget.controller.textFieldFocusNode,
              decoration: const InputDecoration(
                hintText: '输入消息...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              maxLines: null,
              textInputAction: TextInputAction.newline,
              onSubmitted: (_) => _sendMessage(),
              enableInteractiveSelection: true,
              autocorrect: true,
              enableSuggestions: true,
              autofocus: false,
            ),
        ),
      ),
    );
  }

  Widget _buildSendButton(BuildContext context) {
    final isMessageSending = widget.controller.messageHandler?.isMessageSending ?? false;
    final isUploading = widget.controller.isUploadingFiles;
    final isDisabled = isMessageSending || isUploading;
    
    return IconButton(
      onPressed: isDisabled ? null : _sendMessage,
      icon: isDisabled
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            )
          : Icon(
              Icons.send,
              color: Theme.of(context).colorScheme.primary,
            ),
      tooltip: '发送消息',
    );
  }

  void _pickFile(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          final uploadFile = ChatUploadFile(
            path: file.path!,
            name: file.name,
            type: _getFileType(file.extension ?? ''),
          );
          
          uploadFile.isUploading = true;
          widget.controller.uploadFiles.add(uploadFile);
          widget.controller.updateUI();
          
          _uploadFile(uploadFile, context);
          

  
        }
      }
    } catch (e) {
      widget.controller.showTopSnackBar('选择文件失败: \$e', isError: true);
    }
  }

  void _pickImage(BuildContext context) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        final uploadFile = ChatUploadFile(
          path: image.path,
          name: image.name,
          type: 'image',
        );
        
        uploadFile.isUploading = true;
         widget.controller.uploadFiles.add(uploadFile);
         widget.controller.updateUI();
         
         _uploadFile(uploadFile, context);
      }
    } catch (e) {
      widget.controller.showTopSnackBar('选择图片失败: \$e', isError: true);
    }
  }

  String _getFileType(String extension) {
    return FileUtils.getFileType(extension);
  }

  void _uploadFile(ChatUploadFile uploadFile, BuildContext context) async {
    if (widget.controller.messageHandler == null) return;
    
    try {
      await widget.controller.messageHandler!.uploadFile(
        file: uploadFile,
        updateFile: (file) {
  
          final index = widget.controller.uploadFiles.indexWhere((f) => f.path == file.path);
          if (index != -1) {
            widget.controller.uploadFiles[index] = file;
            widget.controller.updateUI();
          }
        },
        setIsUploadingFiles: (isUploading) {
          widget.controller.setIsUploadingFiles(isUploading);
        },
        context: context,
      );
    } catch (e) {
      widget.controller.showTopSnackBar('上传文件失败: \$e', isError: true);
    }
  }

  void _sendMessage() async {
    final text = widget.controller.textController.text.trim();
    if (text.isEmpty && widget.controller.uploadFiles.isEmpty) return;
    
    if (widget.controller.messageHandler == null) {
      widget.controller.showTopSnackBar('请先配置API设置', isError: true);
      return;
    }


    final messageText = text;
    final uploadFiles = List<ChatUploadFile>.from(widget.controller.uploadFiles);
    
    widget.controller.textController.clear();
    widget.controller.uploadFiles.clear();
    widget.controller.updateUI();

    try {
      await widget.controller.messageHandler!.sendMessage(
         currentMessages: widget.controller.conversationManager?.currentMessages ?? [],
         messageText: messageText,
         uploadFiles: uploadFiles,
         currentConversation: widget.controller.conversationManager?.currentConversation,
         updateMessages: (messages) => widget.controller.conversationManager?.currentMessages = messages,
         setAllowSync: (allowSync) => widget.controller.conversationManager?.allowSync = allowSync,
       );
    } catch (e) {
      widget.controller.showTopSnackBar('发送消息失败: \$e', isError: true);

    }
  }
}