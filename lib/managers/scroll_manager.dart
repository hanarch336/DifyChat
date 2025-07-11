import 'dart:async';
import 'package:flutter/material.dart';

class ScrollManager {
  final ScrollController scrollController;
  bool isAtBottom = true;

  bool isScrolling = false;
  Timer? autoScrollTimer;
  bool _isInitialized = false;

  
  // 状态变化通知回调
  VoidCallback? onStateChanged;
  
  ScrollManager({required this.scrollController});
  
  // 初始化滚动监听
  void initialize() {
    scrollController.addListener(_handleScroll);
    
    // 延迟标记为已初始化，确保ListView完全构建
    Future.delayed(const Duration(milliseconds: 200), () {
      _isInitialized = true;
    });
  }
  
  // 处理滚动事件
  void _handleScroll() {
    if (!scrollController.hasClients) return;
    
    final maxScroll = scrollController.position.maxScrollExtent;
    final currentScroll = scrollController.position.pixels;
    const delta = 20.0;
    
    // 更新是否在底部的状态
    isAtBottom = maxScroll - currentScroll <= delta;
    
    // 检测是否正在滚动
    isScrolling = scrollController.position.isScrollingNotifier.value;
  }
  
  // 滚动到底部
  void scrollToBottom() {
    if (!scrollController.hasClients) return;
    
    // 确保ScrollManager已经完全初始化
    if (!_isInitialized) return;
    
    // 确保ScrollController已经附加到可滚动组件并且有内容
    if (!scrollController.position.hasContentDimensions) return;
    
    final maxScroll = scrollController.position.maxScrollExtent;
    final currentScroll = scrollController.position.pixels;
    const delta = 20.0;
    
    // 如果maxScrollExtent为0，说明内容还没有完全加载，跳过滚动
    if (maxScroll <= 0) return;
    
    if (maxScroll - currentScroll <= delta) {
      scrollController.jumpTo(maxScroll);
    } else {
      isScrolling = true;
      scrollController.animateTo(
        maxScroll,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutQuart,
      ).then((_) {
        isScrolling = false;
      });
    }
  }
  
  // 启动自动滚动
  void startAutoScroll({required bool Function() shouldAutoScroll}) {
    autoScrollTimer?.cancel();
    // 降低定时器频率，减少性能消耗
    autoScrollTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (shouldAutoScroll() && !isScrolling) {
        scrollToBottom();
      } else if (!shouldAutoScroll()) {
        timer.cancel();
      }
    });
  }
  
  // 停止自动滚动
  void stopAutoScroll() {
    autoScrollTimer?.cancel();
  }
  

  
  // 释放资源
  void dispose() {
    autoScrollTimer?.cancel();
    scrollController.removeListener(_handleScroll);
  }
}