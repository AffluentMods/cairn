// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Cairn';

  @override
  String get tabMap => 'Map';

  @override
  String get tabPlan => 'Plan';

  @override
  String get tabRecord => 'Record';

  @override
  String get tabLibrary => 'Library';

  @override
  String get phase0Placeholder =>
      'Under construction. Building this screen next.';

  @override
  String get styleOutdoors => 'Outdoors';

  @override
  String get styleTopo => 'Topo';

  @override
  String get styleSatellite => 'Satellite';

  @override
  String get layersTitle => 'Layers';

  @override
  String get layerTrails => 'Trails';

  @override
  String get layerPois => 'Water, camps, peaks';

  @override
  String get layerFires => 'Active fires';

  @override
  String get layerLand => 'Wilderness and park boundaries';

  @override
  String get layerHillshade => 'Hillshade';

  @override
  String get layerConditions => 'Conditions';

  @override
  String get locationPermissionTitle => 'Turn on location';

  @override
  String get locationPermissionBody =>
      'Turn on location to see where you are on the map.';

  @override
  String get backgroundLocationBody =>
      'Cairn records your hike with the screen off. Choose Allow all the time so the track does not stop when you lock your phone.';

  @override
  String get locationOpenSettings => 'Open settings';

  @override
  String get trailUnnamed => 'Unnamed path';

  @override
  String trailSegmentLength(String distance) {
    return '$distance segment';
  }

  @override
  String trailUsfsNumber(String number) {
    return '#$number USFS';
  }

  @override
  String get trailPlanFromHere => 'Plan a route from here';

  @override
  String get trailShowRoute => 'Show route';

  @override
  String get trailsOfflineBanner =>
      'Trail data could not load. Showing saved trails.';

  @override
  String get sacHiking => 'T1 hiking';

  @override
  String get sacMountainHiking => 'T2 mountain hiking';

  @override
  String get sacDemandingMountainHiking => 'T3 demanding';

  @override
  String get sacAlpineHiking => 'T4 alpine';

  @override
  String get sacDemandingAlpineHiking => 'T5 demanding alpine';

  @override
  String get sacDifficultAlpineHiking => 'T6 difficult alpine';

  @override
  String get trailInformal => 'Informal path';

  @override
  String get planTitle => 'Plan';

  @override
  String get planSave => 'Save';

  @override
  String get planUndo => 'Undo';

  @override
  String get planRedo => 'Redo';

  @override
  String get planClear => 'Clear';

  @override
  String get planNameHint => 'Route name';

  @override
  String get planOffTrail => 'Off trail';

  @override
  String get planEmpty =>
      'Tap the map to drop a waypoint. Cairn snaps it to the nearest trail.';

  @override
  String planEstTime(String time) {
    return 'est. $time';
  }

  @override
  String planPackWeight(String weight) {
    return 'pack $weight';
  }

  @override
  String get planWaterHeader => 'Water';

  @override
  String get planWaterLastBeforeClimb => 'last before the climb';

  @override
  String get planWaterSeasonal => 'Seasonal streams may be dry in late summer.';

  @override
  String get planDeleteWaypoint => 'Delete waypoint';

  @override
  String get statDistance => 'distance';

  @override
  String get statGain => 'gain';

  @override
  String get statLoss => 'loss';

  @override
  String get statHighPoint => 'high point';

  @override
  String get statMoving => 'moving';

  @override
  String get statPace => 'pace';

  @override
  String get statSpeed => 'speed';

  @override
  String get statElevation => 'elevation';

  @override
  String get statTotalTime => 'total';

  @override
  String get statCalories => 'calories';

  @override
  String get recordStart => 'Start';

  @override
  String get recordPause => 'Pause';

  @override
  String get recordResume => 'Resume';

  @override
  String get recordFinish => 'Finish';

  @override
  String get recordDiscard => 'Discard';

  @override
  String get recordDiscardConfirm =>
      'Discard this recording? It cannot be recovered.';

  @override
  String recordSavedSummary(String distance, String gain) {
    return 'Saved: $distance, $gain.';
  }

  @override
  String get recordNotificationTitle => 'Recording';

  @override
  String recordNotificationBody(String distance, String time) {
    return '$distance, $time';
  }

  @override
  String get recordOnRoute => 'On route';

  @override
  String get recordOffRoute => 'Off route';

  @override
  String recordToGo(String distance) {
    return '$distance to go';
  }

  @override
  String recordEta(String time) {
    return 'ETA $time';
  }

  @override
  String get recordAutoPaused => 'Auto-paused';

  @override
  String get recordFollowRoute => 'Follow a route';

  @override
  String get recordNoRoute => 'No route';

  @override
  String get recordPackPrompt => 'Pack weight for this hike';

  @override
  String get recordIdle => 'Not recording. Start a hike to see live stats.';

  @override
  String get libraryRoutes => 'Routes';

  @override
  String get libraryTracks => 'Tracks';

  @override
  String get libraryOffline => 'Offline';

  @override
  String get libraryEmptyRoutes => 'No saved routes. Plan one from the map.';

  @override
  String get libraryEmptyTracks => 'No recordings yet.';

  @override
  String get libraryEmptyOffline =>
      'No offline regions. Download one so the map works with no signal.';

  @override
  String get libraryDelete => 'Delete';

  @override
  String get libraryUndo => 'Undo';

  @override
  String get libraryDeleted => 'Deleted';

  @override
  String get gpxImport => 'Import GPX';

  @override
  String get gpxExport => 'Export GPX';

  @override
  String get gpxImportFailed => 'That file could not be read as GPX.';

  @override
  String get gpxImportedRoute => 'Imported route';

  @override
  String get gpxImportedTrack => 'Imported track';

  @override
  String get offlineTitle => 'Offline maps';

  @override
  String get offlineNew => 'New region';

  @override
  String offlineEstimate(String size) {
    return 'about $size';
  }

  @override
  String get offlineLargeWarning =>
      'This region is over 1 GB. Lower the max zoom or shrink the area.';

  @override
  String offlineDownloading(int percent) {
    return 'downloading $percent%';
  }

  @override
  String get offlineIncomplete => 'Incomplete';

  @override
  String get offlineResume => 'Resume';

  @override
  String get offlineRefresh => 'Refresh conditions';

  @override
  String get offlineMaxZoom => 'Max zoom';

  @override
  String get offlineStyles => 'Styles';

  @override
  String get offlineName => 'Region name';

  @override
  String get offlineDownload => 'Download';

  @override
  String condTitle(String name) {
    return 'Conditions for $name';
  }

  @override
  String condUpdatedAgo(String ago) {
    return 'updated $ago';
  }

  @override
  String get condStale => 'stale';

  @override
  String condFireCrosses(String name) {
    return 'Route crosses the $name perimeter';
  }

  @override
  String condFireDistance(String name, String distance) {
    return '$name is $distance from the route';
  }

  @override
  String get condFireNone => 'No active fires within 50 mi';

  @override
  String condFireAcres(String acres) {
    return '$acres ac';
  }

  @override
  String condFireContained(int percent) {
    return '$percent% contained';
  }

  @override
  String get condFireUncontained => '0% contained';

  @override
  String get condFirePrescribed => 'Prescribed burn';

  @override
  String get condOpenInciweb => 'Open on InciWeb';

  @override
  String get condAqi => 'Air quality';

  @override
  String get condAqiModel => 'Model estimate. Monitor data in a later update.';

  @override
  String get condAqiMonitor => 'EPA AirNow monitor';

  @override
  String get aqiGood => 'Good';

  @override
  String get aqiModerate => 'Moderate';

  @override
  String get aqiUsg => 'Unhealthy for sensitive groups';

  @override
  String get aqiUnhealthy => 'Unhealthy';

  @override
  String get aqiVeryUnhealthy => 'Very unhealthy';

  @override
  String get aqiHazardous => 'Hazardous';

  @override
  String get condWeather => 'Weather';

  @override
  String get condTrailhead => 'Trailhead';

  @override
  String get condHighPoint => 'High point';

  @override
  String get condDaylight => 'Daylight';

  @override
  String condDaylightRange(String sunrise, String sunset, String length) {
    return '$sunrise to $sunset ($length)';
  }

  @override
  String condMoon(int percent, String phase) {
    return 'moon $percent% $phase';
  }

  @override
  String get moonNew => 'new';

  @override
  String get moonWaxingCrescent => 'waxing crescent';

  @override
  String get moonFirstQuarter => 'first quarter';

  @override
  String get moonWaxingGibbous => 'waxing gibbous';

  @override
  String get moonFull => 'full';

  @override
  String get moonWaningGibbous => 'waning gibbous';

  @override
  String get moonLastQuarter => 'last quarter';

  @override
  String get moonWaningCrescent => 'waning crescent';

  @override
  String get condLand => 'Land';

  @override
  String get condParking => 'Parking';

  @override
  String get condWildernessPermit => 'Free self-issue permit at the trailhead';

  @override
  String condWildernessEnters(String name) {
    return 'Enters $name';
  }

  @override
  String get condNpsFee => 'Park entrance fee or America the Beautiful pass';

  @override
  String get condNwForestPass =>
      'Northwest Forest Pass or America the Beautiful';

  @override
  String get condDiscoverPass => 'Discover Pass';

  @override
  String condRestrictionStage(int stage) {
    return 'Stage $stage fire restrictions';
  }

  @override
  String condNwsAlert(String event) {
    return '$event';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsUnits => 'Units';

  @override
  String get unitsImperial => 'Miles, feet, degrees F';

  @override
  String get unitsMetric => 'Kilometers, meters, degrees C';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeLight => 'Light';

  @override
  String get settingsDefaultStyle => 'Default map';

  @override
  String get settingsBodyWeight => 'Body weight (for calorie estimates)';

  @override
  String get settingsPackWeight => 'Default pack weight';

  @override
  String get settingsTerrainCache => 'Terrain cache';

  @override
  String get settingsClearCache => 'Clear';

  @override
  String get settingsSources => 'Data sources and attribution';

  @override
  String get settingsPrivacy => 'Privacy';

  @override
  String get settingsLicenses => 'Open source licenses';

  @override
  String settingsVersion(String version) {
    return 'Version $version';
  }

  @override
  String get settingsSync => 'Multi-device sync';

  @override
  String get settingsSyncOff => 'Off';

  @override
  String get settingsSyncOn => 'On';

  @override
  String get syncTitle => 'Multi-device sync';

  @override
  String get syncIntro =>
      'Sync your routes and tracks across devices, end to end encrypted. Off by default. Nothing leaves this device readable.';

  @override
  String get syncEnable => 'Set up sync';

  @override
  String get syncServerUrl => 'Server URL';

  @override
  String get syncPassphrase => 'Passphrase';

  @override
  String get syncPassphraseHint =>
      'You will need this on every device. It cannot be recovered.';

  @override
  String get syncNow => 'Sync now';

  @override
  String get syncStatusIdle => 'Up to date';

  @override
  String get syncStatusSyncing => 'Syncing';

  @override
  String get syncStatusError =>
      'Sync could not finish. Your data is safe on this device.';

  @override
  String syncLastSynced(String ago) {
    return 'Last synced $ago';
  }

  @override
  String get syncDisconnect => 'Disconnect sync';

  @override
  String get syncPurge => 'Delete synced data';

  @override
  String get syncWrongPassphrase =>
      'That passphrase does not match the synced data.';

  @override
  String get syncRecoveryCode => 'Sync code';

  @override
  String get syncRecoveryCodeHint =>
      'Enter this on your other devices to join the same sync.';

  @override
  String get summitTitle => 'Cairn Summit';

  @override
  String get summitOneTime => 'One-time purchase. No subscription.';

  @override
  String get summitRestore => 'Restore purchase';

  @override
  String summitBuy(String price) {
    return 'Unlock for $price';
  }

  @override
  String get summitFeatureOffline => 'Unlimited offline regions';

  @override
  String get summitFeatureWater => 'Water and campsite planning';

  @override
  String get summitFeatureFollow => 'Follow a route while recording';

  @override
  String get summitFeatureAirnow => 'EPA monitor air quality';

  @override
  String get attributionOsm => 'OpenStreetMap contributors';

  @override
  String get attributionOpenFreeMap => 'OpenFreeMap, OpenMapTiles';

  @override
  String get attributionUsgs => 'USGS The National Map';

  @override
  String get attributionTerrain => 'Terrain: Mapzen, AWS Terrain Tiles';

  @override
  String get attributionNifc => 'Fire data: NIFC WFIGS';

  @override
  String get attributionNws => 'Weather: NOAA National Weather Service';

  @override
  String get attributionOpenMeteo => 'Air quality: Open-Meteo';

  @override
  String get genericRetry => 'Retry';

  @override
  String get genericCancel => 'Cancel';

  @override
  String get genericOk => 'OK';

  @override
  String get genericSave => 'Save';

  @override
  String get genericDelete => 'Delete';

  @override
  String get genericClose => 'Close';
}
