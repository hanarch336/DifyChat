import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:flutter/painting.dart';
import 'package:flutter_dify/services/platform_bridge.dart';

class PerformanceOptimizer {
  static final PerformanceOptimizer _instance = PerformanceOptimizer._internal();
  factory PerformanceOptimizer() => _instance;
  PerformanceOptimizer._internal();

  final PlatformBridge _platformBridge = PlatformBridge();
  Timer? _memoryMonitorTimer;
  DateTime? _lastMemoryCleanTime;
  

  Future<void> initialize() async {
    try {
      await _platformBridge.initialize();
      await _setHighPerformanceMode(true);
      _startMemoryMonitoring();
      
      if (!kDebugMode) {
        await _platformBridge.enableNativeMemoryOptimization();
        await _platformBridge.enableGPUAcceleration();
      }
    } catch (e) {
      // Initialization failed
    }
  }
  
  Future<void> _setHighPerformanceMode(bool enabled) async {
    try {
      await _platformBridge.setHighPerformanceMode(enabled);
    } catch (e) {
      if (!kDebugMode) {
        // High performance mode failed
      }
    }
  }
  
  void _startMemoryMonitoring() {
    if (kReleaseMode) {
      _memoryMonitorTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        _checkMemoryUsage();
      });
    }
  }
  
  Future<void> _checkMemoryUsage() async {
    if (kReleaseMode) {
      final now = DateTime.now();
      final lastCleanElapsed = _lastMemoryCleanTime != null 
          ? now.difference(_lastMemoryCleanTime!) 
          : const Duration(minutes: 10);
      
      if (lastCleanElapsed.inMinutes >= 5) {
        await _cleanMemoryIfNeeded();
        _lastMemoryCleanTime = now;
      }
    }
  }
  
  Future<void> _cleanMemoryIfNeeded() async {
    await _forceGarbageCollection();
    
    try {
      final binding = PaintingBinding.instance;
      binding.imageCache.clear();
      binding.imageCache.clearLiveImages();
    } catch (e) {
      // Image cache cleanup failed
    }
  }
  
  Future<void> _forceGarbageCollection() async {
    await compute<void, void>((_) {}, null);
  }
  
  Future<void> prewarmComponents() async {
    if (Platform.isAndroid || Platform.isIOS) {
      await _platformBridge.prewarmImageCodecs();
    }
  }
  
  void optimizeNetworkRequests() {
    HttpClient.enableTimelineLogging = false;
  }
  
  void onAppBackground() {
    _setHighPerformanceMode(false);
  }
  
  void onAppForeground() {
    _setHighPerformanceMode(true);
    _cleanMemoryIfNeeded();
  }
  
  void dispose() {
    _memoryMonitorTimer?.cancel();
    _memoryMonitorTimer = null;
    _setHighPerformanceMode(false);
  }
}