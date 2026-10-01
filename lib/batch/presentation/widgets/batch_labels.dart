import 'package:flutter/material.dart';

import '../../../shared/presentation/l10n/app_localizations.dart';
import '../../../shared/presentation/widgets/status_badge.dart';
import '../../domain/batch.dart';

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

  String label(AppLocalizations l10n) => switch (this) {
    BatchStatus.pending => l10n.batchPending,
    BatchStatus.inProgress => l10n.batchInProgress,
    BatchStatus.released => l10n.batchReleased,
    BatchStatus.rejected => l10n.batchRejected,
    BatchStatus.unknown => l10n.unknown,
  };
}

class BatchStatusBadge extends StatelessWidget {
  const BatchStatusBadge({super.key, required this.status});

  final BatchStatus status;

  @override
  Widget build(BuildContext context) =>
      StatusBadge(label: status.label(context.l10n), tone: status.tone, icon: status.icon);
}
