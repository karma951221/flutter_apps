import '../../../l10n/app_localizations.dart';
import '../domain/entity/report_reason.dart';

extension ReportReasonLocalizations on ReportReason {
  String localized(AppLocalizations l10n) => switch (this) {
    ReportReason.spam => l10n.safetyReportReasonSpam,
    ReportReason.abuse => l10n.safetyReportReasonAbuse,
    ReportReason.sexual => l10n.safetyReportReasonSexual,
    ReportReason.violence => l10n.safetyReportReasonViolence,
    ReportReason.other => l10n.safetyReportReasonOther,
  };
}
