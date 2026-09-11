// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';

/// `context.l10n.keyName` everywhere instead of the verbose
/// `AppLocalizations.of(context).keyName`.
extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
