import 'package:flutter/material.dart';

import '../models/wired_model.dart';
import '../widgets/wiring_canvas.dart';

class WiringViewPage extends StatefulWidget {
  final WiredModel model;
  const WiringViewPage({super.key, required this.model});

  @override
  State<WiringViewPage> createState() => _WiringViewPageState();
}

class _WiringViewPageState extends State<WiringViewPage> {
  bool _showLabels = true;
  // Default on: you wire a prop from the back, not the front/display side
  // the model's own coordinates describe, so the mirrored view is what most
  // people opening this screen actually need.
  bool _showBackside = true;

  @override
  Widget build(BuildContext context) {
    final model = widget.model;
    return Scaffold(
      appBar: AppBar(
        title: Text(model.name),
        actions: [
          IconButton(
            tooltip: _showBackside
                ? 'Showing backside (wiring) view — tap for front/display view'
                : 'Showing front/display view — tap for backside (wiring) view',
            icon: Icon(_showBackside ? Icons.flip_camera_android : Icons.flip_camera_android_outlined),
            onPressed: () => setState(() => _showBackside = !_showBackside),
          ),
          IconButton(
            tooltip: 'Toggle node number labels',
            icon: Icon(_showLabels ? Icons.label : Icons.label_outline),
            onPressed: () => setState(() => _showLabels = !_showLabels),
          ),
        ],
      ),
      body: Column(
        children: [
          Material(
            color: const Color(0xFF22222A),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Chip(label: Text(model.displayAs)),
                  const SizedBox(width: 12),
                  Text('${model.nodes.length} nodes', style: const TextStyle(color: Colors.white70)),
                  const SizedBox(width: 12),
                  Text(_showBackside ? 'Backside view' : 'Front/display view',
                      style: const TextStyle(color: Colors.white54)),
                ],
              ),
            ),
          ),
          Expanded(
            child: WiringCanvas(model: model, showLabels: _showLabels, showBackside: _showBackside),
          ),
        ],
      ),
    );
  }
}
