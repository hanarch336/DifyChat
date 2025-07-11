import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dify/models/message.dart';
import 'package:flutter_dify/managers/settings_manager.dart';
import 'package:flutter_dify/widgets/markdown_renderer.dart';
import 'package:flutter_dify/widgets/file_attachment_widget.dart';
import 'package:provider/provider.dart';

class MessageBubble extends StatefulWidget {
  final Message message;
  final VoidCallback? onRetry;
  final ValueChanged<bool>? onSelectionChanged;
  final bool isSelectionMode;

  const MessageBubble({
    Key? key,
    required this.message,
    this.onRetry,
    this.onSelectionChanged,
    this.isSelectionMode = false,
  }) : super(key: key);

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> with AutomaticKeepAliveClientMixin {
  bool _showActions = false;
  bool _isSelected = false;
  
  // 缓存计算结果，避免重复计算
  Color? _cachedBubbleColor;
  Color? _cachedSelectedColor;
  Color? _cachedTextColor;
  bool? _cachedIsDarkMode;
  String? _cachedMessageId;

  @override
  bool get wantKeepAlive => true; // 保持状态，避免重建

  @override
  void didUpdateWidget(MessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 只有在关键属性变化时才重建
    if (oldWidget.message.id != widget.message.id ||
        oldWidget.message.status != widget.message.status ||
        oldWidget.message.answer != widget.message.answer ||
        oldWidget.isSelectionMode != widget.isSelectionMode) {
      // 强制重建
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 调用AutomaticKeepAliveClientMixin的build方法
    final isUser = widget.message.isUser;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // 只有在主题模式变化或消息ID变化时才重新计算颜色
    if (_cachedIsDarkMode != isDarkMode || _cachedMessageId != widget.message.id) {
      final settingsManager = SettingsManager.cachedSettings ?? 
          Provider.of<SettingsManager>(context, listen: false);
      
      _cachedBubbleColor = isUser 
          ? (isDarkMode ? settingsManager.darkUserBubbleColor : settingsManager.lightUserBubbleColor)
          : (isDarkMode ? settingsManager.darkAiBubbleColor : settingsManager.lightAiBubbleColor);
      
      _cachedSelectedColor = isDarkMode 
          ? settingsManager.darkSelectedBubbleColor 
          : settingsManager.lightSelectedBubbleColor;
      
      final brightness = ThemeData.estimateBrightnessForColor(_cachedBubbleColor!);
      _cachedTextColor = brightness == Brightness.dark ? Colors.white : Colors.black87;
      
      _cachedIsDarkMode = isDarkMode;
      _cachedMessageId = widget.message.id;
    }
    
    final color = _cachedBubbleColor!;
    final selectedColor = _cachedSelectedColor!;
    final textColor = _cachedTextColor!;



    return Align(
      key: ValueKey(widget.message.id),
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // 操作按钮区域
          if (_showActions)
            Container(
              margin: const EdgeInsets.only(bottom: 4.0, left: 8.0, right: 8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: () {
                      // 编辑消息功能
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('编辑功能待实现')),
                      );
                      setState(() {
                        _showActions = false;
                      });
                    },
                    tooltip: '编辑',
                    padding: const EdgeInsets.all(8.0),
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 18),
                    onPressed: () {
                      // 删除消息功能
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('删除功能待实现')),
                      );
                      setState(() {
                        _showActions = false;
                      });
                    },
                    tooltip: '删除',
                    padding: const EdgeInsets.all(8.0),
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: () {
                      // 复制消息内容
                      final text = isUser ? widget.message.query : widget.message.answer;
                      if (text != null && text.isNotEmpty) {
                        Clipboard.setData(ClipboardData(text: text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('已复制到剪贴板')),
                        );
                      }
                      setState(() {
                        _showActions = false;
                      });
                    },
                    tooltip: '复制',
                    padding: const EdgeInsets.all(8.0),
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          if (widget.message.messageFiles != null && widget.message.messageFiles!.isNotEmpty)
            MessageFileAttachment(
              files: widget.message.messageFiles!,
              isUserMessage: isUser,
            ),
          GestureDetector(
            onLongPress: () {
              // 长按只显示操作菜单，不进入选择模式
              setState(() {
                _showActions = !_showActions;
              });
            },
            onTap: widget.isSelectionMode ? () {
              setState(() {
                _isSelected = !_isSelected;
                if (widget.onSelectionChanged != null) {
                  widget.onSelectionChanged!(_isSelected);
                }
              });
            } : () {
              // 普通模式下点击隐藏操作菜单
              if (_showActions) {
                setState(() {
                  _showActions = false;
                });
              }
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: _isSelected && widget.isSelectionMode 
                    ? selectedColor 
                    : (_showActions ? selectedColor : color),
                borderRadius: BorderRadius.circular(20.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              child: _buildMessageContent(context, isUser, textColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context, bool isUser, Color textColor) {
    final displayText = isUser ? widget.message.query ?? '' : widget.message.answer ?? '';
    
    // 用户消息使用普通文本
    if (isUser) {
      return Text(
        displayText,
        style: TextStyle(color: textColor),
      );
    } 
    
    // AI消息使用Markdown渲染，包括加载状态
    if (widget.message.status == MessageStatus.error) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.message.answer ?? '发生错误',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          if (widget.onRetry != null)
            TextButton(
              onPressed: widget.onRetry,
              child: const Text('重试'),
            ),
        ],
      );
    } else {
      // 正常或加载状态都使用Markdown渲染
      final content = widget.message.answer?.isNotEmpty == true 
          ? _preprocessFormulas(widget.message.answer!) 
          : (widget.message.status == MessageStatus.loading ? '正在思考...' : '');
      
      return MarkdownRenderer(
        data: content,
        textColor: textColor,
        style: TextStyle(
          color: textColor,
          fontSize: 14.0, // 明确指定字体大小
        ),
      );
    }
  }
  
  // 预处理公式，确保正确显示
  String _preprocessFormulas(String text) {
    // 处理特殊的LaTeX符号，确保它们能被正确渲染
    
    // 常用数学函数
    final mathFunctions = [
      'frac', 'cos', 'sin', 'tan', 'theta', 'Delta', 'alpha', 'beta', 'gamma',
      'sum', 'int', 'prod', 'lim', 'infty', 'partial', 'nabla', 'cdot', 'times',
      'leq', 'geq', 'neq', 'approx', 'equiv', 'forall', 'exists', 'in', 'notin',
      'subset', 'supset', 'cup', 'cap', 'mathbb', 'mathcal', 'mathrm', 'mathbf',
      'vec', 'overrightarrow', 'hat', 'bar', 'sqrt', 'log', 'ln', 'exp',
      'rightarrow', 'leftarrow', 'Rightarrow', 'Leftarrow'
    ];
    
    // 替换所有数学函数
    for (final func in mathFunctions) {
      // 确保不会重复替换已经转义的命令
      text = text.replaceAll(r'\' + func, r'\\' + func);
    }
    
    return text;
  }
}