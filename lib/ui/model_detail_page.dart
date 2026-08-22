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
  // Which wiring option (index into model.wirings) is currently downloading,
  // if any — lets each option show its own spinner without a single global
  // loading flag disabling every other option too.
  int? _loadingIndex;

  Future<void> _viewWiring(int index, ModelWiring wiring) async {
    setState(() => _loadingIndex = index);
    try {
      final xml = await _downloadService.downloadXmodel(wiring.url);
      final wired = importXModel(xml);
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => WiringViewPage(model: wired)));
    } on XModelImportException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('$e');
    } finally {
      if (mounted) setState(() => _loadingIndex = null);
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
          if (model.wirings.isEmpty)
            const Text('This model has no downloadable .xmodel file.',
                style: TextStyle(color: Colors.white54))
          else ...[
            if (model.wirings.length > 1)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text('Wiring options', style: TextStyle(color: Colors.white54)),
              ),
            for (var i = 0; i < model.wirings.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FilledButton.icon(
                  onPressed: _loadingIndex == null ? () => _viewWiring(i, model.wirings[i]) : null,
                  icon: _loadingIndex == i
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cable),
                  label: Text(_loadingIndex == i
                      ? 'Loading…'
                      : model.wirings.length > 1
                          ? (model.wirings[i].name ?? 'Wiring ${i + 1}')
                          : 'View Wiring'),
                ),
              ),
          ],
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
