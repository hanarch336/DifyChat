import 'package:flutter/material.dart';
import '../models/conversation.dart';

class ConversationDrawer extends StatefulWidget {
  final List<Conversation> conversations;
  final String currentId;
  final Function(Conversation) onSelect;
  final Function(Conversation) onDelete;
  final Function(List<Conversation>) onBatchDelete;
  final Function(Conversation) onRename;
  final VoidCallback onNew;
  final VoidCallback onShowSettings;
  final ScrollController? scrollController;
  final bool isRefreshing;
  final Future<void> Function()? onRefresh;

  const ConversationDrawer({
    Key? key,
    required this.conversations,
    required this.currentId,
    required this.onSelect,
    required this.onDelete,
    required this.onBatchDelete,
    required this.onRename,
    required this.onNew,
    required this.onShowSettings,
    this.scrollController,
    this.isRefreshing = false,
    this.onRefresh,
  }) : super(key: key);

  @override
  State<ConversationDrawer> createState() => _ConversationDrawerState();
}

class _ConversationDrawerState extends State<ConversationDrawer> {
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = <String>{};

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedIds.clear();
      }
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedIds.clear();
      _selectedIds.addAll(widget.conversations.map((c) => c.id));
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedIds.clear();
    });
  }

  void _batchDelete() async {
    if (_selectedIds.isEmpty) return;
    
    final selectedConversations = widget.conversations
        .where((c) => _selectedIds.contains(c.id))
        .toList();
    
    // 显示确认对话框
    final shouldDelete = await _showDeleteConfirmDialog(selectedConversations.length);
    if (!shouldDelete) return;
    
    widget.onBatchDelete(selectedConversations);
    _toggleSelectionMode();
  }
  
  Future<bool> _showDeleteConfirmDialog(int count) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange.shade600,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text('确认删除'),
            ],
          ),
          content: Text(
            '确定要删除选中的 $count 个对话吗？\n\n此操作无法撤销，所有相关的聊天记录都将被永久删除。',
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                '取消',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('删除'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          // 头部区域
          Container(
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'DifyChat',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                  ],
                ),
                const SizedBox(height: 16),
                // 简化的操作区域
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: widget.onNew,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('新建对话'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.primary,
                          backgroundColor: Theme.of(context).colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        onTap: _toggleSelectionMode,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _isSelectionMode ? Icons.close : Icons.checklist,
                            size: 20,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Material(
                      color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        onTap: widget.onShowSettings,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.settings,
                            size: 20,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 刷新状态提示
          if (widget.isRefreshing)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              alignment: Alignment.center,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('正在刷新...'),
                ],
              ),
            ),
          if (!widget.isRefreshing)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              alignment: Alignment.center,
              child: Text(
                '下拉刷新对话列表',
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
              ),
            ),
          // 刷新提示区域已合并到上方
          // 对话列表
          Expanded(
            child: widget.conversations.isEmpty
                ? RefreshIndicator(
                    onRefresh: widget.onRefresh ?? () async {},
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 100),
                        Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 64,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '暂无对话',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '点击"新建对话"开始聊天',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: widget.onRefresh ?? () async {},
                    child: ListView.builder(
                      controller: widget.scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: widget.conversations.length,
                      itemBuilder: (context, index) {
                        final conversation = widget.conversations[index];
                        final isCurrentSelected = conversation.id == widget.currentId;
                        final isMultiSelected = _selectedIds.contains(conversation.id);
                        
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isCurrentSelected && !_isSelectionMode
                                ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
                                : isMultiSelected
                                    ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2)
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isCurrentSelected && !_isSelectionMode
                                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
                                  : isMultiSelected
                                      ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5)
                                      : Colors.transparent,
                              width: 1,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            dense: true,
                            leading: _isSelectionMode
                                ? Checkbox(
                                    value: isMultiSelected,
                                    onChanged: (bool? value) {
                                      _toggleSelection(conversation.id);
                                    },
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  )
                                : Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(
                                      Icons.chat_bubble_outline,
                                      size: 14,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                            title: Text(
                              conversation.name.isNotEmpty ? conversation.name : '新对话',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: isCurrentSelected && !_isSelectionMode 
                                    ? FontWeight.w600 
                                    : FontWeight.w500,
                                fontSize: 13,
                                color: isCurrentSelected && !_isSelectionMode
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 1),
                              child: Text(
                                '${conversation.updatedAt.year}/${conversation.updatedAt.month}/${conversation.updatedAt.day} ${conversation.updatedAt.hour}:${conversation.updatedAt.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                            onTap: () {
                              if (_isSelectionMode) {
                                _toggleSelection(conversation.id);
                              } else {
                                widget.onSelect(conversation);
                              }
                            },
                            onLongPress: () {
                              if (!_isSelectionMode) {
                                _toggleSelectionMode();
                                _toggleSelection(conversation.id);
                              }
                            },
                            trailing: _isSelectionMode
                                ? null
                                : PopupMenuButton(
                                    icon: Icon(
                                      Icons.more_vert,
                                      size: 16,
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        value: 'rename',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.edit_outlined,
                                              size: 18,
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                            const SizedBox(width: 12),
                                            const Text('重命名'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.delete_outline,
                                              size: 18,
                                              color: Colors.red.shade400,
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              '删除',
                                              style: TextStyle(
                                                color: Colors.red.shade400,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    onSelected: (value) {
                                      if (value == 'rename') {
                                        widget.onRename(conversation);
                                      } else if (value == 'delete') {
                                        widget.onDelete(conversation);
                                      }
                                    },
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
          // 底部多选操作栏
          if (_isSelectionMode)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 选择信息
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '已选择 ${_selectedIds.length} 项',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Row(
                          children: [
                            TextButton(
                              onPressed: _selectAll,
                              child: Text(
                                '全选',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: _clearSelection,
                              child: Text(
                                '清空',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // 操作按钮
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _selectedIds.isEmpty ? null : _batchDelete,
                            icon: const Icon(Icons.delete, size: 20),
                            label: const Text('删除选中'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: _selectedIds.isEmpty 
                                  ? Theme.of(context).colorScheme.outline 
                                  : Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ConversationListPanel extends StatelessWidget {
  final List<Conversation> conversations;
  final String currentId;
  final Function(Conversation) onSelect;
  final Function(Conversation) onDelete;
  final Function(Conversation) onRename;
  final VoidCallback onNew;
  final VoidCallback onShowSettings;
  final ScrollController? scrollController;
  final bool isRefreshing;

  const ConversationListPanel({
    Key? key,
    required this.conversations,
    required this.currentId,
    required this.onSelect,
    required this.onDelete,
    required this.onRename,
    required this.onNew,
    required this.onShowSettings,
    this.scrollController,
    this.isRefreshing = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1.0,
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '对话列表',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      onPressed: onNew,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('新建'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        backgroundColor: Theme.of(context).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    IconButton(
                      onPressed: onShowSettings,
                      icon: const Icon(Icons.settings, size: 22),
                      color: Theme.of(context).colorScheme.onPrimary,
                      tooltip: '设置',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 刷新提示已移至主组件
          Expanded(
            child: conversations.isEmpty
                ? const Center(child: Text('暂无对话'))
                : ListView.builder(
                    controller: scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: conversations.length,
                    itemBuilder: (context, index) {
                      final conversation = conversations[index];
                      final isSelected = conversation.id == currentId;
                      return Container(
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
                              : Colors.transparent,
                          border: Border(
                            bottom: BorderSide(
                              color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          title: Text(
                            conversation.name.isNotEmpty ? conversation.name : '新对话',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            '${conversation.updatedAt.year}/${conversation.updatedAt.month}/${conversation.updatedAt.day} ${conversation.updatedAt.hour}:${conversation.updatedAt.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          selected: isSelected,
                          onTap: () => onSelect(conversation),
                          trailing: PopupMenuButton(
                            icon: const Icon(Icons.more_vert, size: 18),
                            padding: EdgeInsets.zero,
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'rename',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 18),
                                    SizedBox(width: 8),
                                    Text('重命名'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, size: 18),
                                    SizedBox(width: 8),
                                    Text('删除'),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) {
                              if (value == 'rename') {
                                onRename(conversation);
                              } else if (value == 'delete') {
                                onDelete(conversation);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}