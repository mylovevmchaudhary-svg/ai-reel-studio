import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/media_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/utils/srt_parser.dart';
import '../../../data/models/caption_model.dart';
import '../../../data/repositories/project_repository.dart';

class SubtitleEditorScreen extends StatefulWidget {
  final String projectId;

  const SubtitleEditorScreen({Key? key, required this.projectId}) : super(key: key);

  @override
  State<SubtitleEditorScreen> createState() => _SubtitleEditorScreenState();
}

class _SubtitleEditorScreenState extends State<SubtitleEditorScreen> {
  final ProjectRepository _repo = ProjectRepository();
  final MediaService _media = MediaService.instance;
  final _uuid = const Uuid();

  List<CaptionModel> _captions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCaptions();
  }

  Future<void> _loadCaptions() async {
    setState(() => _isLoading = true);
    _captions = await _repo.getCaptions(widget.projectId);
    setState(() => _isLoading = false);
  }

  Future<void> _importSrt() async {
    final srtText = await _media.pickSrtFile();
    if (srtText != null) {
      final parsed = SrtParser.parse(srtText, widget.projectId, SupabaseService.instance.currentUserId);
      for (final c in parsed) {
        await _repo.saveCaption(c);
      }
      _loadCaptions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported ${parsed.length} subtitles from SRT! 📝')),
        );
      }
    }
  }

  void _showAddEditSubtitleDialog([CaptionModel? caption]) {
    final textCtrl = TextEditingController(text: caption?.text ?? '');
    final startCtrl = TextEditingController(text: ((caption?.startTimeMs ?? 0) / 1000.0).toStringAsFixed(1));
    final endCtrl = TextEditingController(text: ((caption?.endTimeMs ?? 3000) / 1000.0).toStringAsFixed(1));
    String fontFamily = caption?.fontFamily ?? 'Roboto';
    String animType = caption?.animationType ?? 'pop';
    String position = caption?.position ?? 'bottom';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.cardNavy,
            title: Text(caption == null ? 'Add Subtitle' : 'Edit Subtitle'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: textCtrl,
                    maxLines: 2,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Subtitle Text'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: startCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(labelText: 'Start (sec)'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: endCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(labelText: 'End (sec)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Animation Style Picker
                  DropdownButtonFormField<String>(
                    value: animType,
                    dropdownColor: AppColors.cardNavy,
                    decoration: const InputDecoration(labelText: 'Animation Effect'),
                    items: AppConstants.subtitleAnimations.map((a) {
                      return DropdownMenuItem(value: a.toLowerCase(), child: Text(a));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => animType = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  // Position Picker
                  DropdownButtonFormField<String>(
                    value: position,
                    dropdownColor: AppColors.cardNavy,
                    decoration: const InputDecoration(labelText: 'Screen Position'),
                    items: const [
                      DropdownMenuItem(value: 'bottom', child: Text('Bottom (Standard)')),
                      DropdownMenuItem(value: 'center', child: Text('Center Screen')),
                      DropdownMenuItem(value: 'top', child: Text('Top Header')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => position = val);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  if (textCtrl.text.trim().isEmpty) return;
                  final startSec = double.tryParse(startCtrl.text) ?? 0.0;
                  final endSec = double.tryParse(endCtrl.text) ?? 3.0;

                  final cap = CaptionModel(
                    id: caption?.id ?? _uuid.v4(),
                    projectId: widget.projectId,
                    ownerId: SupabaseService.instance.currentUserId,
                    startTimeMs: (startSec * 1000).toInt(),
                    endTimeMs: (endSec * 1000).toInt(),
                    text: textCtrl.text.trim(),
                    fontFamily: fontFamily,
                    animationType: animType,
                    position: position,
                  );
                  await _repo.saveCaption(cap);
                  Navigator.pop(ctx);
                  _loadCaptions();
                },
                child: const Text('Save Subtitle'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteCaption(String id) async {
    await _repo.deleteCaption(id);
    _loadCaptions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Subtitle & Text Editor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            tooltip: 'Import SRT File',
            onPressed: _importSrt,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Subtitle',
            onPressed: () => _showAddEditSubtitleDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentPurple))
          : _captions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.subtitles_outlined, size: 48, color: Colors.white38),
                      const SizedBox(height: 12),
                      const Text('No subtitles added yet', style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _showAddEditSubtitleDialog(),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Subtitle'),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: _importSrt,
                            icon: const Icon(Icons.file_upload),
                            label: const Text('Import SRT'),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _captions.length,
                  itemBuilder: (context, index) {
                    final c = _captions[index];
                    final startSec = (c.startTimeMs / 1000.0).toStringAsFixed(1);
                    final endSec = (c.endTimeMs / 1000.0).toStringAsFixed(1);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.cardNavy,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withOpacity(0.06)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.warning),
                            ),
                            child: Text(
                              '${startSec}s - ${endSec}s',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.warning),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.text,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Anim: ${c.animationType} • Pos: ${c.position}',
                                  style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.5)),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18, color: Colors.white54),
                            onPressed: () => _showAddEditSubtitleDialog(c),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                            onPressed: () => _deleteCaption(c.id),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
