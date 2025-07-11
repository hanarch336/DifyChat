import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dify/managers/settings_manager.dart';
import 'package:flutter_dify/managers/conversation_manager.dart';
import 'package:flutter_dify/themes/app_theme_config.dart';
import 'package:flutter_dify/widgets/color_picker.dart';
import 'export_service.dart';


class SettingsPage extends StatefulWidget {
  final SettingsManager settingsManager;
  final ConversationManager? conversationManager;
  final Function(SettingsManager) onSettingsChanged;

  const SettingsPage({
    Key? key,
    required this.settingsManager,
    this.conversationManager,
    required this.onSettingsChanged,
  }) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController apiBaseUrlController;
  late TextEditingController apiKeyController;
  late TextEditingController userIdController;
  late TextEditingController proxyHostController;
  late TextEditingController proxyPortController;
  late TextEditingController proxyUserController;
  late TextEditingController proxyPasswordController;
  late TextEditingController syncIntervalController;
  late bool allowBackgroundRunning;
  

  late Color lightUserBubbleColor;
  late Color lightAiBubbleColor;
  late Color lightSelectedBubbleColor;
  

  late Color darkUserBubbleColor;
  late Color darkAiBubbleColor;
  late Color darkSelectedBubbleColor;
  

  Color get userBubbleColor => lightUserBubbleColor;
  Color get aiBubbleColor => lightAiBubbleColor;
  Color get selectedBubbleColor => lightSelectedBubbleColor;
  
  set userBubbleColor(Color color) => lightUserBubbleColor = color;
  set aiBubbleColor(Color color) => lightAiBubbleColor = color;
  set selectedBubbleColor(Color color) => lightSelectedBubbleColor = color;
  

  late ThemeMode themeMode;
  late bool followSystemTheme;


  Timer? _autoSaveTimer;
  

  bool _hasUnsavedChanges = false;
  

  bool testing = false;
  String? testResult;
  

  bool _isTextFieldEditing = false;

  @override
  void initState() {
    super.initState();
    

    apiBaseUrlController = TextEditingController(text: widget.settingsManager.apiBaseUrl);
    apiKeyController = TextEditingController(text: widget.settingsManager.apiKey);
    userIdController = TextEditingController(text: widget.settingsManager.userId);
    proxyHostController = TextEditingController(text: widget.settingsManager.proxyHost ?? '');
    proxyPortController = TextEditingController(text: widget.settingsManager.proxyPort?.toString() ?? '');
    proxyUserController = TextEditingController(text: widget.settingsManager.proxyUser ?? '');
    proxyPasswordController = TextEditingController(text: widget.settingsManager.proxyPassword ?? '');
    syncIntervalController = TextEditingController(text: widget.settingsManager.syncInterval.toString());
    allowBackgroundRunning = widget.settingsManager.allowBackgroundRunning;
    

    lightUserBubbleColor = widget.settingsManager.lightUserBubbleColor;
    lightAiBubbleColor = widget.settingsManager.lightAiBubbleColor;
    lightSelectedBubbleColor = widget.settingsManager.lightSelectedBubbleColor;
    darkUserBubbleColor = widget.settingsManager.darkUserBubbleColor;
    darkAiBubbleColor = widget.settingsManager.darkAiBubbleColor;
    darkSelectedBubbleColor = widget.settingsManager.darkSelectedBubbleColor;
    

    themeMode = widget.settingsManager.themeMode;
    followSystemTheme = widget.settingsManager.followSystemTheme;
    

    if (!followSystemTheme && themeMode == ThemeMode.system) {
      themeMode = ThemeMode.light;
    }
  }

  @override
  void dispose() {

    apiBaseUrlController.dispose();
    apiKeyController.dispose();
    userIdController.dispose();
    proxyHostController.dispose();
    proxyPortController.dispose();
    proxyUserController.dispose();
    proxyPasswordController.dispose();
    syncIntervalController.dispose();
    

    _autoSaveTimer?.cancel();
    

    AppThemeConfig.dispose();
    

    if (_hasUnsavedChanges) {
      _saveSettings();
    }
    
    super.dispose();
  }


  void _onSettingChanged() {
    _hasUnsavedChanges = true;
    

    _autoSaveTimer?.cancel();
    

    _autoSaveTimer = Timer(const Duration(seconds: 1), () {
      if (_hasUnsavedChanges && mounted) {
        _saveSettings();
      }
    });
  }
  


  void _onSwitchChanged(bool value) {
    setState(() {
      allowBackgroundRunning = value;
    });
    _onSettingChanged();
  }
  

  void _onColorChanged(Color color, ColorType type) {
    setState(() {
      switch (type) {
        case ColorType.lightUser:
        case ColorType.user:
          lightUserBubbleColor = color;
          break;
        case ColorType.lightAi:
        case ColorType.ai:
          lightAiBubbleColor = color;
          break;
        case ColorType.lightSelected:
        case ColorType.selected:
          lightSelectedBubbleColor = color;
          break;
        case ColorType.darkUser:
          darkUserBubbleColor = color;
          break;
        case ColorType.darkAi:
          darkAiBubbleColor = color;
          break;
        case ColorType.darkSelected:
          darkSelectedBubbleColor = color;
          break;
      }
    });
    _onSettingChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('应用设置'),
        elevation: 2,
        shadowColor: Theme.of(context).shadowColor,
      ),
      body: GestureDetector(
        onTap: () {

          if (_isTextFieldEditing) {
            setState(() {
              _isTextFieldEditing = false;
            });
            FocusScope.of(context).unfocus();
          }
        },
        child: WillPopScope(
          onWillPop: () async {

            if (_isTextFieldEditing) {
              setState(() {
                _isTextFieldEditing = false;
              });
              FocusScope.of(context).unfocus();
            }
            

            if (_hasUnsavedChanges) {
              await _saveSettings();
            }
            return true;
          },
          child: SingleChildScrollView(

            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: _buildSettingsContent(),
          ),
        ),
      ),

      bottomNavigationBar: const SizedBox(height: 24),

      resizeToAvoidBottomInset: false,
    );
  }

  Widget _buildSettingsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('API设置', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildTextField(
          controller: apiBaseUrlController,
          labelText: 'API Base URL',
          hintText: 'https://api.dify.ai/v1',
        ),
        const SizedBox(height: 8),
        _buildTextField(
          controller: apiKeyController,
          labelText: 'API Key',
          hintText: '输入你的API Key',
        ),
        const SizedBox(height: 8),
        _buildTextField(
          controller: userIdController,
          labelText: 'User ID',
          hintText: '输入你的User ID',
        ),
        const SizedBox(height: 16),
        
        const Text('代理设置（可选）', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildTextField(
          controller: proxyHostController,
          labelText: '代理主机',
          hintText: '例如: 127.0.0.1',
        ),
        const SizedBox(height: 8),
        _buildTextField(
          controller: proxyPortController,
          labelText: '代理端口',
          hintText: '例如: 7890',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 8),
        _buildTextField(
          controller: proxyUserController,
          labelText: '代理用户名（可选）',
        ),
        const SizedBox(height: 8),
        _buildTextField(
          controller: proxyPasswordController,
          labelText: '代理密码（可选）',
          obscureText: true,
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: testing ? null : _testConnectivity,
          child: testing 
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) 
              : const Text('检测连通性'),
        ),
        if (testResult != null) Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            testResult!,
            style: TextStyle(
              color: testResult!.contains('成功') ? Colors.green : Colors.red,
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        const Text('同步设置', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildTextField(
          controller: syncIntervalController,
          labelText: '自动同步间隔（分钟）',
          hintText: '设置为0禁用自动同步',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        
        const Text('后台运行设置', style: TextStyle(fontWeight: FontWeight.bold)),
        SwitchListTile(
          title: const Text('允许后台运行'),
          subtitle: const Text('按返回键时最小化应用而不是退出'),
          value: allowBackgroundRunning,
          onChanged: _onSwitchChanged,
          activeColor: Colors.blue,
          activeTrackColor: Colors.blue.withOpacity(0.5),
          inactiveThumbColor: Theme.of(context).colorScheme.outline,
          inactiveTrackColor: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
        const Divider(),
        
        const Text('主题设置', style: TextStyle(fontWeight: FontWeight.bold)),
        SwitchListTile(
          title: const Text('跟随系统主题'),
          subtitle: const Text('自动切换深浅色主题'),
          value: followSystemTheme,
          onChanged: (value) {
            setState(() {
              followSystemTheme = value;
              if (value) {
                themeMode = ThemeMode.system;
              } else {

                themeMode = ThemeMode.light;
              }
            });

            AppThemeConfig.debounceThemeChange(() {
              widget.settingsManager.updateSettings(
                themeMode: themeMode,
                followSystemTheme: followSystemTheme,
              );
            });
            _onSettingChanged();
          },
          activeColor: Colors.blue,
          activeTrackColor: Colors.blue.withOpacity(0.5),
          inactiveThumbColor: Theme.of(context).colorScheme.outline,
          inactiveTrackColor: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
        if (!followSystemTheme) ...[
          ListTile(
            title: const Text('深色模式'),
            subtitle: Text(themeMode == ThemeMode.dark ? '已启用' : '已禁用'),
            trailing: Switch(
              value: themeMode == ThemeMode.dark,
              onChanged: (bool value) {
                setState(() {
                  themeMode = value ? ThemeMode.dark : ThemeMode.light;
                });

                AppThemeConfig.debounceThemeChange(() {
                  widget.settingsManager.updateSettings(
                    themeMode: themeMode,
                  );
                });
                _onSettingChanged();
              },
              activeColor: Colors.blue,
              activeTrackColor: Colors.blue.withOpacity(0.5),
              inactiveThumbColor: Theme.of(context).colorScheme.outline,
              inactiveTrackColor: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),
          ),
        ],
        const Divider(),
        
        const Text('气泡颜色设置', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('恢复默认颜色'),
              onPressed: () {
                setState(() {
                  lightUserBubbleColor = const Color(0xFF2196F3);
                  lightAiBubbleColor = const Color(0xFFF5F5F5);
                  lightSelectedBubbleColor = const Color(0xFFBBDEFB);
                  
                  darkUserBubbleColor = const Color(0xFF1976D2);
                  darkAiBubbleColor = const Color(0xFF424242);
                  darkSelectedBubbleColor = const Color(0xFF1565C0);
                });
                _onSettingChanged();
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        

        const Padding(
          padding: EdgeInsets.only(top: 16, bottom: 8),
          child: Text('浅色模式颜色', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        ),
        ListTile(
          title: const Text('用户气泡颜色'),
          trailing: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: lightUserBubbleColor,
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          onTap: () => _showColorPicker(context, lightUserBubbleColor, (color) => _onColorChanged(color, ColorType.lightUser)),
        ),
        ListTile(
          title: const Text('AI气泡颜色'),
          trailing: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: lightAiBubbleColor,
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          onTap: () => _showColorPicker(context, lightAiBubbleColor, (color) => _onColorChanged(color, ColorType.lightAi)),
        ),
        ListTile(
          title: const Text('选中气泡颜色'),
          subtitle: const Text('长按消息时显示的颜色'),
          trailing: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: lightSelectedBubbleColor,
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          onTap: () => _showColorPicker(context, lightSelectedBubbleColor, (color) => _onColorChanged(color, ColorType.lightSelected)),
        ),
        

        const Padding(
          padding: EdgeInsets.only(top: 16, bottom: 8),
          child: Text('深色模式颜色', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        ),
        ListTile(
          title: const Text('用户气泡颜色'),
          trailing: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: darkUserBubbleColor,
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          onTap: () => _showColorPicker(context, darkUserBubbleColor, (color) => _onColorChanged(color, ColorType.darkUser)),
        ),
        ListTile(
          title: const Text('AI气泡颜色'),
          trailing: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: darkAiBubbleColor,
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          onTap: () => _showColorPicker(context, darkAiBubbleColor, (color) => _onColorChanged(color, ColorType.darkAi)),
        ),
        ListTile(
          title: const Text('选中气泡颜色'),
          subtitle: const Text('长按消息时显示的颜色'),
          trailing: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: darkSelectedBubbleColor,
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          onTap: () => _showColorPicker(context, darkSelectedBubbleColor, (color) => _onColorChanged(color, ColorType.darkSelected)),
        ),
        

        const Divider(),
        const Padding(
          padding: EdgeInsets.only(top: 16, bottom: 8),
          child: Text('数据管理', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        if (widget.conversationManager != null)
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('导出对话数据'),
            subtitle: const Text('将所有对话导出为JSON格式文件'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              ExportService.showExportDialog(context, widget.conversationManager!);
            },
          ),
        

        const SizedBox(height: 40),
      ],
    );
  }


  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        border: const OutlineInputBorder(),
      ),
      obscureText: obscureText,
      keyboardType: keyboardType,

      onTap: () {
        setState(() {
          _isTextFieldEditing = true;
        });
      },

      onTapOutside: (event) {
        setState(() {
          _isTextFieldEditing = false;
        });
        FocusScope.of(context).unfocus();
      },

      onEditingComplete: () {
        setState(() {
          _isTextFieldEditing = false;
        });
        _onSettingChanged();
      },

      onChanged: (value) {
        _onSettingChanged();
      },
    );
  }


  Future<void> _showColorPicker(BuildContext context, Color initialColor, Function(Color) onColorChanged) async {

    setState(() {
      _isTextFieldEditing = true;
    });
    
    final Color? pickedColor = await showDialog<Color>(
      context: context,
      builder: (BuildContext context) {
        Color currentColor = initialColor;
        return AlertDialog(
          title: const Text('选择颜色'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: initialColor,
              onColorChanged: (Color color) {
                currentColor = color;
              },
              enableAlpha: true,
              labelTypes: const [],
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('确定'),
              onPressed: () {
                Navigator.of(context).pop(currentColor);
              },
            ),
          ],
        );
      },
    );
    

    setState(() {
      _isTextFieldEditing = false;
    });
    
    if (pickedColor != null) {
      onColorChanged(pickedColor);
    }
  }


  Future<void> _testConnectivity() async {
    setState(() {
      testing = true;
      testResult = null;
    });

    final result = await widget.settingsManager.testConnectivity(
      testApiBaseUrl: apiBaseUrlController.text,
      testApiKey: apiKeyController.text,
      testUserId: userIdController.text,
      testProxyHost: proxyHostController.text,
      testProxyPort: proxyPortController.text,
      testProxyUser: proxyUserController.text,
      testProxyPassword: proxyPasswordController.text,
    );

    setState(() {
      testResult = result ?? '连通性检测成功';
      testing = false;
    });
  }


  Future<void> _saveSettings() async {
    try {

      int? syncInterval = int.tryParse(syncIntervalController.text);
      if (syncInterval == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('同步间隔必须是数字'), backgroundColor: Colors.red)
          );
        }
        return;
      }
      

      syncInterval = syncInterval < 0 ? 0 : syncInterval;
      

      final updatedSettings = SettingsManager(
        apiBaseUrl: apiBaseUrlController.text.trim(),
        apiKey: apiKeyController.text.trim(),
        userId: userIdController.text.trim(),
        proxyHost: proxyHostController.text.trim().isNotEmpty ? proxyHostController.text.trim() : null,
        proxyPort: proxyPortController.text.trim().isNotEmpty ? int.tryParse(proxyPortController.text.trim()) : null,
        proxyUser: proxyUserController.text.trim().isNotEmpty ? proxyUserController.text.trim() : null,
        proxyPassword: proxyPasswordController.text.trim().isNotEmpty ? proxyPasswordController.text.trim() : null,
        syncInterval: syncInterval,
        allowBackgroundRunning: allowBackgroundRunning,
        lightUserBubbleColor: lightUserBubbleColor,
        lightAiBubbleColor: lightAiBubbleColor,
        lightSelectedBubbleColor: lightSelectedBubbleColor,
        darkUserBubbleColor: darkUserBubbleColor,
        darkAiBubbleColor: darkAiBubbleColor,
        darkSelectedBubbleColor: darkSelectedBubbleColor,
        themeMode: themeMode,
        followSystemTheme: followSystemTheme,
      );
      

      widget.onSettingsChanged(updatedSettings);
      

      _hasUnsavedChanges = false;
      

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('设置已保存'), 
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          )
        );
      }
      

    } catch (e) {

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存设置时出错: $e'), 
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          )
        );
      }

    }
  }
}

enum ColorType {
  lightUser,
  lightAi,
  lightSelected,
  darkUser,
  darkAi,
  darkSelected,
  user,
  ai,
  selected,
}