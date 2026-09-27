import 'package:l10n/l10n.dart';

import '../../domain/entity/transit_leg.dart';
import '../../domain/entity/transit_mode.dart';

abstract final class CommuteFormat {
  static String duration(AppLocalizations l10n, Duration duration) =>
      l10n.commuteDurationMinutes(duration.inMinutes);

  static String legs(List<TransitLeg> legs) =>
      legs.map((leg) => leg.label).join(' → ');

  static String mode(AppLocalizations l10n, TransitMode mode) => switch (mode) {
    TransitMode.subway => l10n.commuteModeSubway,
    TransitMode.bus => l10n.commuteModeBus,
    TransitMode.best => l10n.commuteModeBest,
  };
}
