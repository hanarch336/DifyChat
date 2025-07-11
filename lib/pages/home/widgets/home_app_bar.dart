import 'package:flutter/material.dart';
import 'package:flutter_dify/models/conversation.dart';
import 'package:flutter_dify/pages/home/controllers/home_controller.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dify/managers/settings_manager.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final HomeController controller;
  final bool isSelectionMode;
  final int selectedCount;
  final Conversation? currentConversation;

  const HomeAppBar({
    Key? key,
    required this.controller,
    required this.isSelectionMode,
    required this.selectedCount,
    this.currentConversation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settingsManager = Provider.of<SettingsManager>(context);
    
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () => controller.toggleDrawer(),
        tooltip: '打开对话列表',
      ),
      title: isSelectionMode
          ? Text('已选择 $selectedCount 条消息')
          : Row(
              children: [
                Expanded(
                  child: Text(
                    currentConversation?.name ?? 'DifyChat',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (currentConversation != null)
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => _showRenameDialog(context),
                    tooltip: '修改对话名称',
                  ),
              ],
            ),
      actions: isSelectionMode
          ? _buildSelectionActions(context)
          : _buildNormalActions(context, settingsManager),
    );
  }

  List<Widget> _buildSelectionActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.copy),
        onPressed: () => _copySelectedMessages(context),
        tooltip: '复制选中消息',
      ),
      IconButton(
        icon: const Icon(Icons.delete),
        onPressed: () => _deleteSelectedMessages(context),
        tooltip: '删除选中消息',
      ),
      IconButton(
        icon: const Icon(Icons.close),
        onPressed: () {
          controller.selectionManager.exitSelectionMode();
        },
        tooltip: '退出选择模式',
      ),
    ];
  }

  List<Widget> _buildNormalActions(BuildContext context, SettingsManager settingsManager) {
    return [
      IconButton(
        icon: const Icon(Icons.checklist),
        onPressed: () {
          controller.selectionManager.enterSelectionMode();
        },
        tooltip: '进入多选模式',
      ),
      IconButton(
        icon: const Icon(Icons.add_comment),
        onPressed: () => controller.conversationManager?.newConversation(),
        tooltip: '新建对话',
      ),
    ];
  }

  void _showRenameDialog(BuildContext context) {
    if (currentConversation == null) return;
    
    final TextEditingController nameController = TextEditingController(
      text: currentConversation!.name,
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('修改对话名称'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            hintText: '请输入新的对话名称',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty && newName != currentConversation!.name) {
                controller.conversationManager?.renameConversation(
                  currentConversation!,
                  newName,
                );
              }
              Navigator.of(context).pop();
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _copySelectedMessages(BuildContext context) {
    controller.selectionManager.copySelectedMessages(
      controller.conversationManager?.currentMessages ?? [],
      context,
    );
  }

  void _deleteSelectedMessages(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除选中的 $selectedCount 条消息吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              controller.selectionManager.deleteSelectedMessages(
                context,
              );
              Navigator.of(context).pop();
            },
            child: Text('删除', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }



  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}