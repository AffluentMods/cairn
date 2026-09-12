// SPDX-License-Identifier: GPL-3.0-or-later
import '../../l10n/app_localizations.dart';

/// "just now", "12 min", "3 h", "2 d": the age of a fetch or an update, for
/// "updated {ago}" style copy (spec Phase 7 freshness rules).
String formatAgo(AppLocalizations l10n, DateTime t, {DateTime? now}) {
  final d = (now ?? DateTime.now()).difference(t);
  if (d.inMinutes < 1) return l10n.agoJustNow;
  if (d.inMinutes < 60) return l10n.agoMinutes(d.inMinutes);
  if (d.inHours < 24) return l10n.agoHours(d.inHours);
  return l10n.agoDays(d.inDays);
}
