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
  bool _showLabels = false;

  @override
  Widget build(BuildContext context) {
    final model = widget.model;
    return Scaffold(
      appBar: AppBar(
        title: Text(model.name),
        actions: [
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
                ],
              ),
            ),
          ),
          Expanded(
            child: WiringCanvas(model: model, showLabels: _showLabels),
          ),
        ],
      ),
    );
  }
}
