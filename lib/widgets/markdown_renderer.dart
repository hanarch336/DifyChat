import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_highlight/themes/vs2015.dart';

class MarkdownRenderer extends StatelessWidget {
  final String data;
  final Color? textColor;
  final TextStyle? style;
  
  const MarkdownRenderer({
    Key? key,
    required this.data,
    this.textColor,
    this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fontSize = style?.fontSize ?? 14.0;
    final defaultStyle = style ?? TextStyle(
      color: textColor ?? theme.textTheme.bodyMedium?.color,
      fontSize: fontSize,
    );
    
    return MarkdownBody(
      data: data,
      selectable: false,
      styleSheet: MarkdownStyleSheet(
        p: defaultStyle,
        h1: defaultStyle.copyWith(
          fontSize: fontSize * 1.8,
          fontWeight: FontWeight.bold,
        ),
        h2: defaultStyle.copyWith(
          fontSize: fontSize * 1.6,
          fontWeight: FontWeight.bold,
        ),
        h3: defaultStyle.copyWith(
          fontSize: fontSize * 1.4,
          fontWeight: FontWeight.bold,
        ),
        h4: defaultStyle.copyWith(
          fontSize: fontSize * 1.2,
          fontWeight: FontWeight.bold,
        ),
        h5: defaultStyle.copyWith(
          fontSize: fontSize * 1.1,
          fontWeight: FontWeight.bold,
        ),
        h6: defaultStyle.copyWith(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
        code: defaultStyle.copyWith(
          fontFamily: 'JetBrains Mono, Consolas, Monaco, monospace',
          fontSize: (defaultStyle.fontSize ?? 14) * 0.9,
          backgroundColor: theme.brightness == Brightness.dark
              ? theme.colorScheme.surfaceVariant.withOpacity(0.8)
              : Colors.grey[200],
          color: theme.brightness == Brightness.dark
              ? theme.colorScheme.primary
              : Colors.red[700],
          fontWeight: FontWeight.w500,
        ),
        codeblockDecoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        blockquote: defaultStyle.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.7),
          fontStyle: FontStyle.italic,
        ),
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: theme.colorScheme.primary,
              width: 4,
            ),
          ),
        ),
        listBullet: defaultStyle,
        tableHead: defaultStyle.copyWith(
          fontWeight: FontWeight.bold,
        ),
        tableBody: defaultStyle,
        tableBorder: TableBorder.all(
           color: theme.colorScheme.outline.withOpacity(0.2),
         ),
      ),
      builders: {
        'code': CodeElementBuilder(codeStyle: defaultStyle),
      },
      extensionSet: md.ExtensionSet(
        md.ExtensionSet.gitHubFlavored.blockSyntaxes,
        md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
      ),
      onTapLink: (text, href, title) {
         if (href != null) {
           _handleLinkTap(href);
         }
       },
    );
  }
  
  /// 处理链接点击
  void _handleLinkTap(String href) {
    debugPrint('Link tapped: $href');
  }
}

/// 自定义代码块构建器，支持语法高亮和复制功能
class CodeElementBuilder extends MarkdownElementBuilder {
  final TextStyle? codeStyle;
  
  CodeElementBuilder({this.codeStyle});
  
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    if (element.tag == 'code' && element.children?.isNotEmpty == true) {
      final code = element.textContent;
      final language = element.attributes['class']?.replaceFirst('language-', '') ?? '';
      
      // 判断是否为行内代码：没有语言标识且代码不包含换行符
      final isInlineCode = language.isEmpty && !code.contains('\n');
      
      if (isInlineCode) {
        // 行内代码样式
        return Builder(
          builder: (context) {
            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;
            
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: isDark 
                    ? theme.colorScheme.surfaceVariant.withOpacity(0.8)
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                code,
                style: (codeStyle ?? const TextStyle()).copyWith(
                  fontFamily: 'monospace',
                  fontSize: (codeStyle?.fontSize ?? 14) * 0.9,
                  color: isDark 
                      ? theme.colorScheme.primary
                      : Colors.red[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          },
        );
      }
      
      // 代码块样式
      return Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;
          
          return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? theme.colorScheme.surface : Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 代码块头部
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark 
                        ? theme.colorScheme.surfaceVariant.withOpacity(0.3)
                        : Colors.grey[200],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        language.isNotEmpty ? language.toUpperCase() : 'TEXT',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark 
                              ? theme.colorScheme.onSurface.withOpacity(0.7)
                              : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: code));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('代码已复制到剪贴板'),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.content_copy_rounded,
                            size: 14,
                            color: isDark 
                                ? theme.colorScheme.onSurface.withOpacity(0.7)
                                : Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // 代码内容
                Container(
                  padding: const EdgeInsets.all(12),
                  child: language.isNotEmpty
                      ? HighlightView(
                          code,
                          language: language,
                          theme: isDark ? vs2015Theme : githubTheme,
                          padding: EdgeInsets.zero,
                          textStyle: TextStyle(
                            fontFamily: 'JetBrains Mono, Consolas, Monaco, monospace',
                            fontSize: 13,
                            height: 1.4,
                          ),
                        )
                      : SelectableText(
                          code,
                          style: TextStyle(
                            fontFamily: 'JetBrains Mono, Consolas, Monaco, monospace',
                            fontSize: 13,
                            height: 1.4,
                            color: isDark 
                                ? theme.colorScheme.onSurface
                                : Colors.black87,
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      );
    }
    return null;
  }
}