import 'package:flutter/material.dart';
import '../../../controllers/upload_controller.dart';
import '../../../core/theme/app_theme.dart';

class PipelineProgress extends StatelessWidget {
  final UploadStage currentStage;
  const PipelineProgress({super.key, required this.currentStage});

  static const _stages = [
    _StageInfo(UploadStage.uploading,  '☁️', 'Uploading file'),
    _StageInfo(UploadStage.extracting, '📖', 'Extracting text'),
    _StageInfo(UploadStage.chunking,   '✂️', 'Chunking document'),
    _StageInfo(UploadStage.embedding,  '🧠', 'Creating embeddings'),
    _StageInfo(UploadStage.done,       '✅', 'Ready!'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _stages.map((s) => _StageRow(
        info:       s,
        status:     _getStatus(s.stage),
      )).toList(),
    );
  }

  _StageStatus _getStatus(UploadStage stage) {
    if (currentStage == UploadStage.error) return _StageStatus.pending;
    if (currentStage == UploadStage.done)  return _StageStatus.done;

    final stages     = _stages.map((s) => s.stage).toList();
    final currentIdx = stages.indexOf(currentStage);
    final stageIdx   = stages.indexOf(stage);

    if (stageIdx < currentIdx)  return _StageStatus.done;
    if (stageIdx == currentIdx) return _StageStatus.active;
    return _StageStatus.pending;
  }
}

enum _StageStatus { pending, active, done }

class _StageRow extends StatelessWidget {
  final _StageInfo info;
  final _StageStatus status;
  const _StageRow({required this.info, required this.status});

  @override
  Widget build(BuildContext context) {
    final Color color = switch (status) {
      _StageStatus.done    => AppColors.success,
      _StageStatus.active  => AppColors.primary,
      _StageStatus.pending => AppColors.textHint,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Icon circle
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withAlpha(30),
              border: Border.all(color: color.withAlpha(80)),
            ),
            child: Center(
              child: status == _StageStatus.active
                  ? SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    )
                  : Text(info.emoji,
                      style: const TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 14),

          // Label
          Text(
            info.label,
            style: TextStyle(
              color:      color,
              fontWeight: status == _StageStatus.active
                  ? FontWeight.w600
                  : FontWeight.normal,
            ),
          ),

          const Spacer(),

          // Status indicator
          if (status == _StageStatus.done)
            const Icon(Icons.check_circle, color: AppColors.success, size: 18),
        ],
      ),
    );
  }
}

class _StageInfo {
  final UploadStage stage;
  final String emoji;
  final String label;
  const _StageInfo(this.stage, this.emoji, this.label);
}
