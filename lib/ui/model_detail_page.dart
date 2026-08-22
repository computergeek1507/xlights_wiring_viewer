import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/vendor_model.dart';
import '../services/xmodel_download_service.dart';
import '../services/xmodel_importer.dart';
import 'wiring_view_page.dart';

class ModelDetailPage extends StatefulWidget {
  final VendorModel model;
  const ModelDetailPage({super.key, required this.model});

  @override
  State<ModelDetailPage> createState() => _ModelDetailPageState();
}

class _ModelDetailPageState extends State<ModelDetailPage> {
  final _downloadService = XmodelDownloadService();
  bool _loading = false;

  Future<void> _viewWiring() async {
    final url = widget.model.xmodelUrl;
    if (url == null) {
      _showError('This model has no downloadable .xmodel file.');
      return;
    }
    setState(() => _loading = true);
    try {
      final xml = await _downloadService.downloadXmodel(url);
      final wired = importXModel(xml);
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => WiringViewPage(model: wired)));
    } on XModelImportException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = widget.model;
    return Scaffold(
      appBar: AppBar(title: Text(model.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (model.imageFile != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: model.imageFile!,
                fit: BoxFit.contain,
                height: 220,
                errorWidget: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          const SizedBox(height: 16),
          _detailRow('Type', model.type),
          _detailRow('Material', model.material),
          _detailRow('Width', model.width),
          _detailRow('Height', model.height),
          _detailRow('Thickness', model.thickness),
          _detailRow('Pixel count', model.pixelCount?.toString()),
          _detailRow('Pixel description', model.pixelDescription),
          _detailRow('Pixel spacing', model.pixelSpacing),
          if (model.notes != null && model.notes!.isNotEmpty) _detailRow('Notes', model.notes),
          if (model.weblink != null) _detailRow('Vendor page', model.weblink),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _loading ? null : _viewWiring,
            icon: _loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cable),
            label: Text(_loading ? 'Loading…' : 'View Wiring'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(color: Colors.white54)),
          ),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }
}
