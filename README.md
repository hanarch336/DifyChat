# Flutter Dify

基于 Dify API 构建的跨平台原生应用项目。

## 项目简介

本项目是一个基于 [Dify](https://dify.ai/) API 构建的原生移动应用，支持 Android、iOS（施工中） 和桌面平台。通过导入 DSL 配置文件，您可以快速创建和部署自己的 AI 助手应用。

## 主要特性

- 🚀 **跨平台支持**：支持 Android、iOS、Windows、macOS 和 Linux
- 🤖 **Dify API 集成**：完整支持 Dify 平台的对话 API
- 📱 **原生体验**：使用 Flutter 构建，提供流畅的原生应用体验
- 🎨 **自定义主题**：支持浅色/深色主题切换和自定义颜色
- 💬 **智能对话**：支持文本对话、文件上传和多媒体交互
- ⚙️ **灵活配置**：通过 DSL 文件快速配置 AI 助手行为
- 🔄 **实时同步**：支持对话历史的本地缓存和云端同步
- 🌐 **代理支持**：内置 HTTP 代理配置，适应不同网络环境

## 快速开始

### 环境要求

- Flutter SDK 3.0+
- Dart 3.0+
- Android Studio / VS Code
- 有效的 Dify API 密钥


## 配置说明

### Dify API 配置

在应用的设置页面中，您需要配置以下信息：

- **API Base URL**：您的 Dify 实例地址
- **API Key**：从 Dify 控制台获取的 API 密钥
- **User ID**：用户标识符（自拟，无需从服务端获取，但是需要在不同的设备上保持一致，以便同步对话）
- **DSL 配置**：在 Dify 导入适配本项目的的DSL配置文件：[DifyChat.yml](DifyChat.yml)

### 代理配置（可选）

如果您的网络环境需要代理，可以在设置中配置：

- 代理主机地址
- 代理端口
- 代理用户名和密码（如需要）

## 项目结构

```
lib/
├── main.dart                 # 应用入口
├── app.dart                  # 应用配置
├── managers/                 # 状态管理
│   ├── conversation_manager.dart
│   ├── settings_manager.dart
│   └── ...
├── models/                   # 数据模型
│   ├── conversation.dart
│   ├── message.dart
│   └── ...
├── pages/                    # 页面组件
│   ├── home/
│   ├── settings/
│   └── ...
├── services/                 # 服务层
│   ├── conversation_api.dart
│   ├── platform_bridge.dart
│   └── ...
├── widgets/                  # 通用组件
│   ├── message_bubble.dart
│   ├── markdown_renderer.dart
│   └── ...
└── themes/                   # 主题配置
    └── app_theme_config.dart
```

## 功能特性

### 对话管理
- 创建和管理多个对话
- 对话历史本地缓存
- 支持文件上传和多媒体消息
- Markdown 渲染支持

### 用户体验
- 流畅的消息滚动和动画
- 自适应的消息气泡样式
- 支持消息选择和复制
- 智能的键盘处理

### 平台特性
- Android：支持后台运行和系统集成
- Windows：系统托盘和原生窗口控制
- 跨平台的文件选择和处理

## 开发指南

### 添加新功能

1. 在相应的 `managers/` 目录下添加状态管理
2. 在 `services/` 目录下添加 API 服务
3. 在 `pages/` 或 `widgets/` 目录下添加 UI 组件
4. 更新相关的数据模型

### 自定义主题

编辑 `themes/app_theme_config.dart` 文件来自定义应用主题：

```dart
// 自定义颜色
static const Color primaryColor = Color(0xFF2196F3);
static const Color accentColor = Color(0xFF03DAC6);
```

## 贡献指南

欢迎提交 Issue 和 Pull Request 来改进这个项目！

1. Fork 本仓库
2. 创建您的特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交您的更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开一个 Pull Request

## 许可证

本项目采用 MIT 许可证。详情请参阅 [LICENSE](LICENSE) 文件。

## 相关链接

- [Dify 官网](https://dify.ai/)
- [Dify API 文档](https://docs.dify.ai/)
- [Flutter 官方文档](https://docs.flutter.dev/)

## 支持

如果您在使用过程中遇到问题，请：

1. 查看 [Issues](https://github.com/hanarch336/DifyChat/issues) 页面
2. 创建新的 Issue 描述您的问题
3. 或者通过邮件联系我们

---

**注意**：使用本应用前，请确保您已经在 Dify 平台创建了相应的应用并获取了有效的 API 密钥。
