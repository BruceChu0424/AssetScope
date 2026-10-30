import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'asset_globe.dart';

/// 全屏资产地球（沉浸模式）：从首页取景框的「全屏」入口进入。
/// 交互、自转与标记详情都在 [AssetGlobe]；这里只提供深空底与进出通道。
class GlobePage extends StatelessWidget {
  const GlobePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050A12),
      appBar: AppBar(
        title: const Text('资产地球'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.tealAccent,
        actions: [
          IconButton(
            tooltip: '返回总览',
            icon: const Icon(Icons.close_fullscreen, color: Colors.tealAccent),
            onPressed: () => context.go('/'),
          ),
        ],
      ),
      body: const AssetGlobe(),
    );
  }
}
