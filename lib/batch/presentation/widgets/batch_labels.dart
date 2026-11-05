import 'package:flutter/material.dart';

import '../../../common/presentation/i18n/app_localizations.dart';
import '../../../common/presentation/widgets/status_badge.dart';
import '../../domain/entities/batch_status.dart';

extension BatchStatusPresentation on BatchStatus {
  BadgeTone get tone => switch (this) {
    BatchStatus.pending => BadgeTone.warning,
    BatchStatus.inProgress => BadgeTone.info,
    BatchStatus.released => BadgeTone.success,
    BatchStatus.rejected => BadgeTone.critical,
    BatchStatus.unknown => BadgeTone.neutral,
  };

  IconData get icon => switch (this) {
    BatchStatus.pending => Icons.hourglass_top_rounded,
    BatchStatus.inProgress => Icons.autorenew_rounded,
    BatchStatus.released => Icons.verified_outlined,
    BatchStatus.rejected => Icons.block_outlined,
    BatchStatus.unknown => Icons.help_outline,
  };

  String label(AppLocalizations i18n) => switch (this) {
    BatchStatus.pending => i18n.batchPending,
    BatchStatus.inProgress => i18n.batchInProgress,
    BatchStatus.released => i18n.batchReleased,
    BatchStatus.rejected => i18n.batchRejected,
    BatchStatus.unknown => i18n.unknown,
  };
}

class BatchStatusBadge extends StatelessWidget {
  const BatchStatusBadge({super.key, required this.status});

  final BatchStatus status;

  @override
  Widget build(BuildContext context) =>
      StatusBadge(label: status.label(context.i18n), tone: status.tone, icon: status.icon);
}
