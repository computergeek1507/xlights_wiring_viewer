import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/xmodel_importer.dart';
import 'vendor_list_page.dart';
import 'wiring_view_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _loadLocalFile(BuildContext context) async {
    // withData (not path): web has no filesystem path, only in-memory bytes,
    // and reading bytes works identically on mobile/desktop too.
    final result = await FilePicker.pickFiles(
      dialogTitle: 'Open an xLights .xmodel file',
      type: FileType.custom,
      allowedExtensions: const ['xmodel'],
      withData: true,
    );
    final bytes = result?.files.single.bytes;
    if (bytes == null) return;
    if (!context.mounted) return;

    try {
      final xml = utf8.decode(bytes);
      final model = importXModel(xml);
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => WiringViewPage(model: model)),
      );
    } on XModelImportException catch (e) {
      if (context.mounted) _showError(context, e.message);
    } catch (e) {
      if (context.mounted) _showError(context, 'Could not read file: $e');
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('xLights Wiring Viewer')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cable, size: 64, color: Colors.white38),
                const SizedBox(height: 16),
                const Text(
                  'View the physical pixel wiring order of an xLights model.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const VendorListPage()),
                  ),
                  icon: const Icon(Icons.store),
                  label: const Text('Browse Vendor Catalog'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _loadLocalFile(context),
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Load .xmodel from device'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
