import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// The app name, shown in the launcher and About.
  ///
  /// In en, this message translates to:
  /// **'Cairn'**
  String get appName;

  /// Temporary body for screens not built yet.
  ///
  /// In en, this message translates to:
  /// **'Under construction. Building this screen next.'**
  String get phase0Placeholder;

  /// No description provided for @styleOutdoors.
  ///
  /// In en, this message translates to:
  /// **'Outdoors'**
  String get styleOutdoors;

  /// No description provided for @styleTopo.
  ///
  /// In en, this message translates to:
  /// **'Topo'**
  String get styleTopo;

  /// No description provided for @styleSatellite.
  ///
  /// In en, this message translates to:
  /// **'Satellite'**
  String get styleSatellite;

  /// No description provided for @layerTrails.
  ///
  /// In en, this message translates to:
  /// **'Trails'**
  String get layerTrails;

  /// No description provided for @layerPois.
  ///
  /// In en, this message translates to:
  /// **'Water, camps, peaks'**
  String get layerPois;

  /// No description provided for @layerFires.
  ///
  /// In en, this message translates to:
  /// **'Active fires'**
  String get layerFires;

  /// No description provided for @layerLand.
  ///
  /// In en, this message translates to:
  /// **'Wilderness and park boundaries'**
  String get layerLand;

  /// No description provided for @layerConditions.
  ///
  /// In en, this message translates to:
  /// **'Conditions'**
  String get layerConditions;

  /// No description provided for @locationPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn on location'**
  String get locationPermissionTitle;

  /// No description provided for @locationPermissionBody.
  ///
  /// In en, this message translates to:
  /// **'Turn on location to see where you are on the map.'**
  String get locationPermissionBody;

  /// No description provided for @backgroundLocationBody.
  ///
  /// In en, this message translates to:
  /// **'Cairn records your hike with the screen off. Choose Allow all the time so the track does not stop when you lock your phone.'**
  String get backgroundLocationBody;

  /// No description provided for @locationOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get locationOpenSettings;

  /// No description provided for @locationNoFix.
  ///
  /// In en, this message translates to:
  /// **'No GPS fix yet. Try again outside or near a window.'**
  String get locationNoFix;

  /// No description provided for @locationServicesOff.
  ///
  /// In en, this message translates to:
  /// **'Location is off on this phone.'**
  String get locationServicesOff;

  /// No description provided for @trailUnnamed.
  ///
  /// In en, this message translates to:
  /// **'Unnamed path'**
  String get trailUnnamed;

  /// No description provided for @trailSegmentLength.
  ///
  /// In en, this message translates to:
  /// **'{distance} segment'**
  String trailSegmentLength(String distance);

  /// No description provided for @trailUsfsNumber.
  ///
  /// In en, this message translates to:
  /// **'#{number} USFS'**
  String trailUsfsNumber(String number);

  /// No description provided for @trailPlanFromHere.
  ///
  /// In en, this message translates to:
  /// **'Plan a route from here'**
  String get trailPlanFromHere;

  /// No description provided for @trailShowRoute.
  ///
  /// In en, this message translates to:
  /// **'Show route'**
  String get trailShowRoute;

  /// No description provided for @trailsOfflineBanner.
  ///
  /// In en, this message translates to:
  /// **'Trail data could not load. Showing saved trails.'**
  String get trailsOfflineBanner;

  /// No description provided for @sacHiking.
  ///
  /// In en, this message translates to:
  /// **'T1 hiking'**
  String get sacHiking;

  /// No description provided for @sacMountainHiking.
  ///
  /// In en, this message translates to:
  /// **'T2 mountain hiking'**
  String get sacMountainHiking;

  /// No description provided for @sacDemandingMountainHiking.
  ///
  /// In en, this message translates to:
  /// **'T3 demanding'**
  String get sacDemandingMountainHiking;

  /// No description provided for @sacAlpineHiking.
  ///
  /// In en, this message translates to:
  /// **'T4 alpine'**
  String get sacAlpineHiking;

  /// No description provided for @sacDemandingAlpineHiking.
  ///
  /// In en, this message translates to:
  /// **'T5 demanding alpine'**
  String get sacDemandingAlpineHiking;

  /// No description provided for @sacDifficultAlpineHiking.
  ///
  /// In en, this message translates to:
  /// **'T6 difficult alpine'**
  String get sacDifficultAlpineHiking;

  /// No description provided for @trailInformal.
  ///
  /// In en, this message translates to:
  /// **'Informal path'**
  String get trailInformal;

  /// No description provided for @planTitle.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get planTitle;

  /// No description provided for @planSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get planSave;

  /// No description provided for @planUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get planUndo;

  /// No description provided for @planRedo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get planRedo;

  /// No description provided for @planClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get planClear;

  /// No description provided for @planNameHint.
  ///
  /// In en, this message translates to:
  /// **'Route name'**
  String get planNameHint;

  /// No description provided for @planOffTrail.
  ///
  /// In en, this message translates to:
  /// **'Off trail'**
  String get planOffTrail;

  /// No description provided for @planEmpty.
  ///
  /// In en, this message translates to:
  /// **'Tap the map to drop a waypoint. Cairn snaps it to the nearest trail.'**
  String get planEmpty;

  /// No description provided for @planEstTime.
  ///
  /// In en, this message translates to:
  /// **'est. {time}'**
  String planEstTime(String time);

  /// No description provided for @planPackWeight.
  ///
  /// In en, this message translates to:
  /// **'pack {weight}'**
  String planPackWeight(String weight);

  /// No description provided for @planWaterHeader.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get planWaterHeader;

  /// No description provided for @planWaterLastBeforeClimb.
  ///
  /// In en, this message translates to:
  /// **'last before the climb'**
  String get planWaterLastBeforeClimb;

  /// No description provided for @planWaterSeasonal.
  ///
  /// In en, this message translates to:
  /// **'Seasonal streams may be dry in late summer.'**
  String get planWaterSeasonal;

  /// No description provided for @planDeleteWaypoint.
  ///
  /// In en, this message translates to:
  /// **'Delete waypoint'**
  String get planDeleteWaypoint;

  /// No description provided for @statDistance.
  ///
  /// In en, this message translates to:
  /// **'distance'**
  String get statDistance;

  /// No description provided for @statGain.
  ///
  /// In en, this message translates to:
  /// **'gain'**
  String get statGain;

  /// No description provided for @statLoss.
  ///
  /// In en, this message translates to:
  /// **'loss'**
  String get statLoss;

  /// No description provided for @statHighPoint.
  ///
  /// In en, this message translates to:
  /// **'high point'**
  String get statHighPoint;

  /// No description provided for @statMoving.
  ///
  /// In en, this message translates to:
  /// **'moving'**
  String get statMoving;

  /// No description provided for @statPace.
  ///
  /// In en, this message translates to:
  /// **'pace'**
  String get statPace;

  /// No description provided for @statSpeed.
  ///
  /// In en, this message translates to:
  /// **'speed'**
  String get statSpeed;

  /// No description provided for @statElevation.
  ///
  /// In en, this message translates to:
  /// **'elevation'**
  String get statElevation;

  /// No description provided for @statTotalTime.
  ///
  /// In en, this message translates to:
  /// **'total'**
  String get statTotalTime;

  /// No description provided for @statCalories.
  ///
  /// In en, this message translates to:
  /// **'calories'**
  String get statCalories;

  /// No description provided for @recordStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get recordStart;

  /// No description provided for @recordPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get recordPause;

  /// No description provided for @recordResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get recordResume;

  /// No description provided for @recordFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get recordFinish;

  /// No description provided for @recordDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get recordDiscard;

  /// No description provided for @recordDiscardConfirm.
  ///
  /// In en, this message translates to:
  /// **'Discard this recording? It cannot be recovered.'**
  String get recordDiscardConfirm;

  /// No description provided for @recordSavedSummary.
  ///
  /// In en, this message translates to:
  /// **'Saved: {distance}, {gain}.'**
  String recordSavedSummary(String distance, String gain);

  /// No description provided for @recordNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get recordNotificationTitle;

  /// No description provided for @recordNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'{distance}, {time}'**
  String recordNotificationBody(String distance, String time);

  /// No description provided for @recordOnRoute.
  ///
  /// In en, this message translates to:
  /// **'On route'**
  String get recordOnRoute;

  /// No description provided for @recordOffRoute.
  ///
  /// In en, this message translates to:
  /// **'Off route'**
  String get recordOffRoute;

  /// No description provided for @recordToGo.
  ///
  /// In en, this message translates to:
  /// **'{distance} to go'**
  String recordToGo(String distance);

  /// No description provided for @recordEta.
  ///
  /// In en, this message translates to:
  /// **'ETA {time}'**
  String recordEta(String time);

  /// No description provided for @recordAutoPaused.
  ///
  /// In en, this message translates to:
  /// **'Auto-paused'**
  String get recordAutoPaused;

  /// No description provided for @recordFollowRoute.
  ///
  /// In en, this message translates to:
  /// **'Follow a route'**
  String get recordFollowRoute;

  /// No description provided for @recordNoRoute.
  ///
  /// In en, this message translates to:
  /// **'No route'**
  String get recordNoRoute;

  /// No description provided for @recordPackPrompt.
  ///
  /// In en, this message translates to:
  /// **'Pack weight for this hike'**
  String get recordPackPrompt;

  /// No description provided for @recordIdle.
  ///
  /// In en, this message translates to:
  /// **'Not recording. Start a hike to see live stats.'**
  String get recordIdle;

  /// No description provided for @libraryEmptyOffline.
  ///
  /// In en, this message translates to:
  /// **'No offline regions. Download one so the map works with no signal.'**
  String get libraryEmptyOffline;

  /// No description provided for @libraryDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get libraryDelete;

  /// No description provided for @libraryUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get libraryUndo;

  /// No description provided for @libraryDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get libraryDeleted;

  /// No description provided for @gpxImport.
  ///
  /// In en, this message translates to:
  /// **'Import GPX'**
  String get gpxImport;

  /// No description provided for @gpxExport.
  ///
  /// In en, this message translates to:
  /// **'Export GPX'**
  String get gpxExport;

  /// No description provided for @gpxImportFailed.
  ///
  /// In en, this message translates to:
  /// **'That file could not be read as GPX.'**
  String get gpxImportFailed;

  /// No description provided for @gpxImportedRoute.
  ///
  /// In en, this message translates to:
  /// **'Imported route'**
  String get gpxImportedRoute;

  /// No description provided for @gpxImportedTrack.
  ///
  /// In en, this message translates to:
  /// **'Imported track'**
  String get gpxImportedTrack;

  /// No description provided for @offlineTitle.
  ///
  /// In en, this message translates to:
  /// **'Offline maps'**
  String get offlineTitle;

  /// No description provided for @offlineNew.
  ///
  /// In en, this message translates to:
  /// **'New region'**
  String get offlineNew;

  /// No description provided for @offlineEstimate.
  ///
  /// In en, this message translates to:
  /// **'about {size}'**
  String offlineEstimate(String size);

  /// No description provided for @offlineLargeWarning.
  ///
  /// In en, this message translates to:
  /// **'This region is over 1 GB. Lower the max zoom or shrink the area.'**
  String get offlineLargeWarning;

  /// No description provided for @offlineDownloading.
  ///
  /// In en, this message translates to:
  /// **'downloading {percent}%'**
  String offlineDownloading(int percent);

  /// No description provided for @offlineIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Incomplete'**
  String get offlineIncomplete;

  /// No description provided for @offlineResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get offlineResume;

  /// No description provided for @offlineRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh conditions'**
  String get offlineRefresh;

  /// No description provided for @offlineMaxZoom.
  ///
  /// In en, this message translates to:
  /// **'Max zoom'**
  String get offlineMaxZoom;

  /// No description provided for @offlineStyles.
  ///
  /// In en, this message translates to:
  /// **'Styles'**
  String get offlineStyles;

  /// No description provided for @offlineName.
  ///
  /// In en, this message translates to:
  /// **'Region name'**
  String get offlineName;

  /// No description provided for @offlineDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get offlineDownload;

  /// No description provided for @condTitle.
  ///
  /// In en, this message translates to:
  /// **'Conditions for {name}'**
  String condTitle(String name);

  /// No description provided for @condUpdatedAgo.
  ///
  /// In en, this message translates to:
  /// **'updated {ago}'**
  String condUpdatedAgo(String ago);

  /// No description provided for @condStale.
  ///
  /// In en, this message translates to:
  /// **'stale'**
  String get condStale;

  /// No description provided for @condFireCrosses.
  ///
  /// In en, this message translates to:
  /// **'Route crosses the {name} perimeter'**
  String condFireCrosses(String name);

  /// No description provided for @condFireDistance.
  ///
  /// In en, this message translates to:
  /// **'{name} is {distance} from the route'**
  String condFireDistance(String name, String distance);

  /// No description provided for @condFireNone.
  ///
  /// In en, this message translates to:
  /// **'No active fires within 50 mi'**
  String get condFireNone;

  /// No description provided for @condFireAcres.
  ///
  /// In en, this message translates to:
  /// **'{acres} ac'**
  String condFireAcres(String acres);

  /// No description provided for @condFireContained.
  ///
  /// In en, this message translates to:
  /// **'{percent}% contained'**
  String condFireContained(int percent);

  /// No description provided for @condFireUncontained.
  ///
  /// In en, this message translates to:
  /// **'0% contained'**
  String get condFireUncontained;

  /// No description provided for @condFirePrescribed.
  ///
  /// In en, this message translates to:
  /// **'Prescribed burn'**
  String get condFirePrescribed;

  /// No description provided for @condOpenInciweb.
  ///
  /// In en, this message translates to:
  /// **'Open on InciWeb'**
  String get condOpenInciweb;

  /// No description provided for @condAqi.
  ///
  /// In en, this message translates to:
  /// **'Air quality'**
  String get condAqi;

  /// No description provided for @condAqiModel.
  ///
  /// In en, this message translates to:
  /// **'Model estimate. Monitor data in a later update.'**
  String get condAqiModel;

  /// No description provided for @condAqiMonitor.
  ///
  /// In en, this message translates to:
  /// **'EPA AirNow monitor'**
  String get condAqiMonitor;

  /// No description provided for @aqiGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get aqiGood;

  /// No description provided for @aqiModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get aqiModerate;

  /// No description provided for @aqiUsg.
  ///
  /// In en, this message translates to:
  /// **'Unhealthy for sensitive groups'**
  String get aqiUsg;

  /// No description provided for @aqiUnhealthy.
  ///
  /// In en, this message translates to:
  /// **'Unhealthy'**
  String get aqiUnhealthy;

  /// No description provided for @aqiVeryUnhealthy.
  ///
  /// In en, this message translates to:
  /// **'Very unhealthy'**
  String get aqiVeryUnhealthy;

  /// No description provided for @aqiHazardous.
  ///
  /// In en, this message translates to:
  /// **'Hazardous'**
  String get aqiHazardous;

  /// No description provided for @condWeather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get condWeather;

  /// No description provided for @condTrailhead.
  ///
  /// In en, this message translates to:
  /// **'Trailhead'**
  String get condTrailhead;

  /// No description provided for @condHighPoint.
  ///
  /// In en, this message translates to:
  /// **'High point'**
  String get condHighPoint;

  /// No description provided for @condDaylight.
  ///
  /// In en, this message translates to:
  /// **'Daylight'**
  String get condDaylight;

  /// No description provided for @condDaylightRange.
  ///
  /// In en, this message translates to:
  /// **'{sunrise} to {sunset} ({length})'**
  String condDaylightRange(String sunrise, String sunset, String length);

  /// No description provided for @condMoon.
  ///
  /// In en, this message translates to:
  /// **'moon {percent}% {phase}'**
  String condMoon(int percent, String phase);

  /// No description provided for @moonNew.
  ///
  /// In en, this message translates to:
  /// **'new'**
  String get moonNew;

  /// No description provided for @moonWaxingCrescent.
  ///
  /// In en, this message translates to:
  /// **'waxing crescent'**
  String get moonWaxingCrescent;

  /// No description provided for @moonFirstQuarter.
  ///
  /// In en, this message translates to:
  /// **'first quarter'**
  String get moonFirstQuarter;

  /// No description provided for @moonWaxingGibbous.
  ///
  /// In en, this message translates to:
  /// **'waxing gibbous'**
  String get moonWaxingGibbous;

  /// No description provided for @moonFull.
  ///
  /// In en, this message translates to:
  /// **'full'**
  String get moonFull;

  /// No description provided for @moonWaningGibbous.
  ///
  /// In en, this message translates to:
  /// **'waning gibbous'**
  String get moonWaningGibbous;

  /// No description provided for @moonLastQuarter.
  ///
  /// In en, this message translates to:
  /// **'last quarter'**
  String get moonLastQuarter;

  /// No description provided for @moonWaningCrescent.
  ///
  /// In en, this message translates to:
  /// **'waning crescent'**
  String get moonWaningCrescent;

  /// No description provided for @condLand.
  ///
  /// In en, this message translates to:
  /// **'Land'**
  String get condLand;

  /// No description provided for @condParking.
  ///
  /// In en, this message translates to:
  /// **'Parking'**
  String get condParking;

  /// No description provided for @condWildernessPermit.
  ///
  /// In en, this message translates to:
  /// **'Free self-issue permit at the trailhead'**
  String get condWildernessPermit;

  /// No description provided for @condWildernessEnters.
  ///
  /// In en, this message translates to:
  /// **'Enters {name}'**
  String condWildernessEnters(String name);

  /// No description provided for @condNpsFee.
  ///
  /// In en, this message translates to:
  /// **'Park entrance fee or America the Beautiful pass'**
  String get condNpsFee;

  /// No description provided for @condNwForestPass.
  ///
  /// In en, this message translates to:
  /// **'Northwest Forest Pass or America the Beautiful'**
  String get condNwForestPass;

  /// No description provided for @condDiscoverPass.
  ///
  /// In en, this message translates to:
  /// **'Discover Pass'**
  String get condDiscoverPass;

  /// No description provided for @condRestrictionStage.
  ///
  /// In en, this message translates to:
  /// **'Stage {stage} fire restrictions'**
  String condRestrictionStage(int stage);

  /// No description provided for @condNwsAlert.
  ///
  /// In en, this message translates to:
  /// **'{event}'**
  String condNwsAlert(String event);

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsUnits.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get settingsUnits;

  /// No description provided for @unitsImperial.
  ///
  /// In en, this message translates to:
  /// **'Miles, feet, degrees F'**
  String get unitsImperial;

  /// No description provided for @unitsMetric.
  ///
  /// In en, this message translates to:
  /// **'Kilometers, meters, degrees C'**
  String get unitsMetric;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @settingsDefaultStyle.
  ///
  /// In en, this message translates to:
  /// **'Default map'**
  String get settingsDefaultStyle;

  /// No description provided for @settingsBodyWeight.
  ///
  /// In en, this message translates to:
  /// **'Body weight (for calorie estimates)'**
  String get settingsBodyWeight;

  /// No description provided for @settingsPackWeight.
  ///
  /// In en, this message translates to:
  /// **'Default pack weight'**
  String get settingsPackWeight;

  /// No description provided for @settingsTerrainCache.
  ///
  /// In en, this message translates to:
  /// **'Terrain cache'**
  String get settingsTerrainCache;

  /// No description provided for @settingsClearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get settingsClearCache;

  /// No description provided for @settingsSources.
  ///
  /// In en, this message translates to:
  /// **'Data sources and attribution'**
  String get settingsSources;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsPrivacy;

  /// No description provided for @settingsLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open source licenses'**
  String get settingsLicenses;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String settingsVersion(String version);

  /// No description provided for @settingsSync.
  ///
  /// In en, this message translates to:
  /// **'Multi-device sync'**
  String get settingsSync;

  /// No description provided for @settingsSyncOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get settingsSyncOff;

  /// No description provided for @settingsSyncOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get settingsSyncOn;

  /// No description provided for @syncTitle.
  ///
  /// In en, this message translates to:
  /// **'Multi-device sync'**
  String get syncTitle;

  /// No description provided for @syncIntro.
  ///
  /// In en, this message translates to:
  /// **'Sync your routes and tracks across devices, end to end encrypted. Off by default. Nothing leaves this device readable.'**
  String get syncIntro;

  /// No description provided for @syncEnable.
  ///
  /// In en, this message translates to:
  /// **'Set up sync'**
  String get syncEnable;

  /// No description provided for @syncServerUrl.
  ///
  /// In en, this message translates to:
  /// **'Server URL'**
  String get syncServerUrl;

  /// No description provided for @syncPassphrase.
  ///
  /// In en, this message translates to:
  /// **'Passphrase'**
  String get syncPassphrase;

  /// No description provided for @syncPassphraseHint.
  ///
  /// In en, this message translates to:
  /// **'You will need this on every device. It cannot be recovered.'**
  String get syncPassphraseHint;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncNow;

  /// No description provided for @syncStatusIdle.
  ///
  /// In en, this message translates to:
  /// **'Up to date'**
  String get syncStatusIdle;

  /// No description provided for @syncStatusSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing'**
  String get syncStatusSyncing;

  /// No description provided for @syncStatusError.
  ///
  /// In en, this message translates to:
  /// **'Sync could not finish. Your data is safe on this device.'**
  String get syncStatusError;

  /// No description provided for @syncLastSynced.
  ///
  /// In en, this message translates to:
  /// **'Last synced {ago}'**
  String syncLastSynced(String ago);

  /// No description provided for @syncDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect sync'**
  String get syncDisconnect;

  /// No description provided for @syncPurge.
  ///
  /// In en, this message translates to:
  /// **'Delete synced data'**
  String get syncPurge;

  /// No description provided for @syncWrongPassphrase.
  ///
  /// In en, this message translates to:
  /// **'That passphrase does not match the synced data.'**
  String get syncWrongPassphrase;

  /// No description provided for @syncRecoveryCode.
  ///
  /// In en, this message translates to:
  /// **'Sync code'**
  String get syncRecoveryCode;

  /// No description provided for @syncRecoveryCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter this on your other devices to join the same sync.'**
  String get syncRecoveryCodeHint;

  /// No description provided for @syncJoin.
  ///
  /// In en, this message translates to:
  /// **'Join with a code'**
  String get syncJoin;

  /// No description provided for @syncCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Sync code copied'**
  String get syncCodeCopied;

  /// No description provided for @syncEnabled.
  ///
  /// In en, this message translates to:
  /// **'Sync is on'**
  String get syncEnabled;

  /// No description provided for @syncNoData.
  ///
  /// In en, this message translates to:
  /// **'No synced data found for that code.'**
  String get syncNoData;

  /// No description provided for @syncPassphraseTooShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least 10 characters. The passphrase is the only thing protecting your data if your sync code is exposed.'**
  String get syncPassphraseTooShort;

  /// No description provided for @summitTitle.
  ///
  /// In en, this message translates to:
  /// **'Cairn Summit'**
  String get summitTitle;

  /// No description provided for @summitOneTime.
  ///
  /// In en, this message translates to:
  /// **'One-time purchase. No subscription.'**
  String get summitOneTime;

  /// No description provided for @summitRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore purchase'**
  String get summitRestore;

  /// No description provided for @summitBuy.
  ///
  /// In en, this message translates to:
  /// **'Unlock for {price}'**
  String summitBuy(String price);

  /// No description provided for @summitFeatureOffline.
  ///
  /// In en, this message translates to:
  /// **'Unlimited offline regions'**
  String get summitFeatureOffline;

  /// No description provided for @summitFeatureWater.
  ///
  /// In en, this message translates to:
  /// **'Water and campsite planning'**
  String get summitFeatureWater;

  /// No description provided for @summitFeatureFollow.
  ///
  /// In en, this message translates to:
  /// **'Follow a route while recording'**
  String get summitFeatureFollow;

  /// No description provided for @summitFeatureAirnow.
  ///
  /// In en, this message translates to:
  /// **'EPA monitor air quality'**
  String get summitFeatureAirnow;

  /// No description provided for @attributionOsm.
  ///
  /// In en, this message translates to:
  /// **'OpenStreetMap contributors'**
  String get attributionOsm;

  /// No description provided for @attributionOpenFreeMap.
  ///
  /// In en, this message translates to:
  /// **'OpenFreeMap, OpenMapTiles'**
  String get attributionOpenFreeMap;

  /// No description provided for @attributionUsgs.
  ///
  /// In en, this message translates to:
  /// **'USGS The National Map'**
  String get attributionUsgs;

  /// No description provided for @attributionTerrain.
  ///
  /// In en, this message translates to:
  /// **'Terrain: Mapzen, AWS Terrain Tiles'**
  String get attributionTerrain;

  /// No description provided for @attributionNifc.
  ///
  /// In en, this message translates to:
  /// **'Fire data: NIFC WFIGS'**
  String get attributionNifc;

  /// No description provided for @attributionNws.
  ///
  /// In en, this message translates to:
  /// **'Weather: NOAA National Weather Service'**
  String get attributionNws;

  /// No description provided for @attributionOpenMeteo.
  ///
  /// In en, this message translates to:
  /// **'Air quality: Open-Meteo'**
  String get attributionOpenMeteo;

  /// No description provided for @genericRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get genericRetry;

  /// No description provided for @genericCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get genericCancel;

  /// No description provided for @genericOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get genericOk;

  /// No description provided for @genericSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get genericSave;

  /// No description provided for @genericDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get genericDelete;

  /// No description provided for @genericClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get genericClose;

  /// No description provided for @genericSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get genericSkip;

  /// No description provided for @genericDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get genericDone;

  /// No description provided for @genericCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get genericCopy;

  /// No description provided for @genericClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get genericClear;

  /// No description provided for @designerTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme Designer'**
  String get designerTitle;

  /// No description provided for @designerNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New theme'**
  String get designerNewTitle;

  /// No description provided for @designerName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get designerName;

  /// No description provided for @designerNameHint.
  ///
  /// In en, this message translates to:
  /// **'My theme'**
  String get designerNameHint;

  /// No description provided for @designerStartFrom.
  ///
  /// In en, this message translates to:
  /// **'Start from'**
  String get designerStartFrom;

  /// No description provided for @designerColors.
  ///
  /// In en, this message translates to:
  /// **'Colors'**
  String get designerColors;

  /// No description provided for @designerExportFile.
  ///
  /// In en, this message translates to:
  /// **'Export as file'**
  String get designerExportFile;

  /// No description provided for @designerExportCode.
  ///
  /// In en, this message translates to:
  /// **'Copy theme code'**
  String get designerExportCode;

  /// No description provided for @designerImport.
  ///
  /// In en, this message translates to:
  /// **'Import a theme'**
  String get designerImport;

  /// No description provided for @designerImportHint.
  ///
  /// In en, this message translates to:
  /// **'Paste a cairn-theme code or file contents'**
  String get designerImportHint;

  /// No description provided for @designerCopied.
  ///
  /// In en, this message translates to:
  /// **'Theme code copied'**
  String get designerCopied;

  /// No description provided for @designerImported.
  ///
  /// In en, this message translates to:
  /// **'Theme imported'**
  String get designerImported;

  /// No description provided for @designerImportFailed.
  ///
  /// In en, this message translates to:
  /// **'That is not a valid theme'**
  String get designerImportFailed;

  /// No description provided for @designerDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this theme?'**
  String get designerDeleteConfirm;

  /// No description provided for @designerUnnamed.
  ///
  /// In en, this message translates to:
  /// **'Untitled theme'**
  String get designerUnnamed;

  /// No description provided for @tokenAccent.
  ///
  /// In en, this message translates to:
  /// **'Accent'**
  String get tokenAccent;

  /// No description provided for @tokenBackground.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get tokenBackground;

  /// No description provided for @tokenSurface.
  ///
  /// In en, this message translates to:
  /// **'Surface'**
  String get tokenSurface;

  /// No description provided for @tokenRaised.
  ///
  /// In en, this message translates to:
  /// **'Raised'**
  String get tokenRaised;

  /// No description provided for @tokenOutline.
  ///
  /// In en, this message translates to:
  /// **'Outline'**
  String get tokenOutline;

  /// No description provided for @tokenText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get tokenText;

  /// No description provided for @tokenSecondary.
  ///
  /// In en, this message translates to:
  /// **'Secondary text'**
  String get tokenSecondary;

  /// No description provided for @tokenRoute.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get tokenRoute;

  /// No description provided for @tokenTrack.
  ///
  /// In en, this message translates to:
  /// **'Track'**
  String get tokenTrack;

  /// No description provided for @tabExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get tabExplore;

  /// No description provided for @tabNavigate.
  ///
  /// In en, this message translates to:
  /// **'Navigate'**
  String get tabNavigate;

  /// No description provided for @tabSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get tabSaved;

  /// No description provided for @tabActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get tabActivity;

  /// No description provided for @exploreSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search trails and places'**
  String get exploreSearchHint;

  /// No description provided for @exploreTrailsInView.
  ///
  /// In en, this message translates to:
  /// **'Trails in view'**
  String get exploreTrailsInView;

  /// No description provided for @exploreSectionInView.
  ///
  /// In en, this message translates to:
  /// **'Section in view'**
  String get exploreSectionInView;

  /// No description provided for @exploreDistanceAway.
  ///
  /// In en, this message translates to:
  /// **'{distance} away'**
  String exploreDistanceAway(String distance);

  /// No description provided for @exploreEmpty.
  ///
  /// In en, this message translates to:
  /// **'No trails in this area yet. Zoom in or pan to load them.'**
  String get exploreEmpty;

  /// No description provided for @trailNavigate.
  ///
  /// In en, this message translates to:
  /// **'Navigate this trail'**
  String get trailNavigate;

  /// No description provided for @trailSave.
  ///
  /// In en, this message translates to:
  /// **'Save trail'**
  String get trailSave;

  /// No description provided for @trailUnsave.
  ///
  /// In en, this message translates to:
  /// **'Remove from saved'**
  String get trailUnsave;

  /// No description provided for @navEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No route loaded'**
  String get navEmptyTitle;

  /// No description provided for @navEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Pick a trail in Explore, or draw your own.'**
  String get navEmptyBody;

  /// No description provided for @navCustomizeRoute.
  ///
  /// In en, this message translates to:
  /// **'Customize route'**
  String get navCustomizeRoute;

  /// No description provided for @navDirections.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get navDirections;

  /// No description provided for @navDirectionsFailed.
  ///
  /// In en, this message translates to:
  /// **'No app could open directions.'**
  String get navDirectionsFailed;

  /// No description provided for @navDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get navDownload;

  /// No description provided for @navDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get navDownloaded;

  /// No description provided for @navDownloadNotOffline.
  ///
  /// In en, this message translates to:
  /// **'This map type cannot be saved offline. Switch to Outdoors, Topo, Terrain, or Road.'**
  String get navDownloadNotOffline;

  /// No description provided for @navRouteArea.
  ///
  /// In en, this message translates to:
  /// **'Route area'**
  String get navRouteArea;

  /// No description provided for @navStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get navStart;

  /// No description provided for @navDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get navDone;

  /// No description provided for @navClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get navClear;

  /// No description provided for @navDiscardChanges.
  ///
  /// In en, this message translates to:
  /// **'Discard changes to this route?'**
  String get navDiscardChanges;

  /// No description provided for @nav3dView.
  ///
  /// In en, this message translates to:
  /// **'3D view'**
  String get nav3dView;

  /// No description provided for @nav3dNeedsConnection.
  ///
  /// In en, this message translates to:
  /// **'3D view needs a connection. The flat map works offline.'**
  String get nav3dNeedsConnection;

  /// No description provided for @nav3dFlyAlong.
  ///
  /// In en, this message translates to:
  /// **'Fly along route'**
  String get nav3dFlyAlong;

  /// No description provided for @nav3dResetNorth.
  ///
  /// In en, this message translates to:
  /// **'Reset north'**
  String get nav3dResetNorth;

  /// No description provided for @navRecenter.
  ///
  /// In en, this message translates to:
  /// **'Recenter'**
  String get navRecenter;

  /// No description provided for @navClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get navClose;

  /// No description provided for @routeUnnamed.
  ///
  /// In en, this message translates to:
  /// **'Unnamed route'**
  String get routeUnnamed;

  /// No description provided for @mapLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading map'**
  String get mapLoading;

  /// No description provided for @mapLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'The map did not load.'**
  String get mapLoadFailed;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @appearanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceTitle;

  /// No description provided for @appearanceModeHeader.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get appearanceModeHeader;

  /// No description provided for @appearanceDarkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark theme'**
  String get appearanceDarkTheme;

  /// No description provided for @appearanceLightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light theme'**
  String get appearanceLightTheme;

  /// No description provided for @appearanceCreate.
  ///
  /// In en, this message translates to:
  /// **'Create a theme'**
  String get appearanceCreate;

  /// No description provided for @appearancePreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get appearancePreview;

  /// No description provided for @settingsDeveloper.
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get settingsDeveloper;

  /// No description provided for @settingsSimulateLocation.
  ///
  /// In en, this message translates to:
  /// **'Simulate location'**
  String get settingsSimulateLocation;

  /// No description provided for @settingsSimulateLocationSub.
  ///
  /// In en, this message translates to:
  /// **'Walk the loaded route instead of using GPS. Start recording to begin.'**
  String get settingsSimulateLocationSub;

  /// No description provided for @settingsDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics'**
  String get settingsDiagnostics;

  /// No description provided for @diagnosticsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'On-device crash and stall log'**
  String get diagnosticsSubtitle;

  /// No description provided for @diagnosticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics'**
  String get diagnosticsTitle;

  /// No description provided for @diagnosticsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No issues logged. Crashes and slow frames appear here.'**
  String get diagnosticsEmpty;

  /// No description provided for @diagnosticsExplainer.
  ///
  /// In en, this message translates to:
  /// **'This log stays on your device. It never contains your location, and nothing is sent anywhere unless you share it.'**
  String get diagnosticsExplainer;

  /// No description provided for @diagnosticsShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get diagnosticsShare;

  /// No description provided for @diagnosticsClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get diagnosticsClear;

  /// No description provided for @layersMapType.
  ///
  /// In en, this message translates to:
  /// **'Map type'**
  String get layersMapType;

  /// No description provided for @layersOverlays.
  ///
  /// In en, this message translates to:
  /// **'Overlays'**
  String get layersOverlays;

  /// No description provided for @layersHillshade.
  ///
  /// In en, this message translates to:
  /// **'Hillshade'**
  String get layersHillshade;

  /// No description provided for @layersTilt.
  ///
  /// In en, this message translates to:
  /// **'Tilt'**
  String get layersTilt;

  /// No description provided for @styleTerrain.
  ///
  /// In en, this message translates to:
  /// **'Terrain'**
  String get styleTerrain;

  /// No description provided for @styleRoad.
  ///
  /// In en, this message translates to:
  /// **'Road'**
  String get styleRoad;

  /// No description provided for @styleIgnPlan.
  ///
  /// In en, this message translates to:
  /// **'IGN Plan'**
  String get styleIgnPlan;

  /// No description provided for @coverageUsOnly.
  ///
  /// In en, this message translates to:
  /// **'US only'**
  String get coverageUsOnly;

  /// No description provided for @coverageFranceOnly.
  ///
  /// In en, this message translates to:
  /// **'France only'**
  String get coverageFranceOnly;

  /// No description provided for @overlayRadar.
  ///
  /// In en, this message translates to:
  /// **'Precipitation radar'**
  String get overlayRadar;

  /// No description provided for @overlayRadarSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Radar now, updates every 5 min'**
  String get overlayRadarSubtitle;

  /// No description provided for @overlayTemperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature forecast'**
  String get overlayTemperature;

  /// No description provided for @overlayTemperatureSubtitle.
  ///
  /// In en, this message translates to:
  /// **'NWS forecast'**
  String get overlayTemperatureSubtitle;

  /// No description provided for @overlaySnowDepth.
  ///
  /// In en, this message translates to:
  /// **'Snow depth'**
  String get overlaySnowDepth;

  /// No description provided for @overlaySnowDepthSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Modeled, updated several times a day'**
  String get overlaySnowDepthSubtitle;

  /// No description provided for @overlaySlope.
  ///
  /// In en, this message translates to:
  /// **'Slope angle'**
  String get overlaySlope;

  /// No description provided for @overlaySlopeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'From USGS elevation data'**
  String get overlaySlopeSubtitle;

  /// No description provided for @overlayLidarHillshade.
  ///
  /// In en, this message translates to:
  /// **'Lidar hillshade'**
  String get overlayLidarHillshade;

  /// No description provided for @overlayLidarHillshadeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'USGS 3DEP, best available resolution'**
  String get overlayLidarHillshadeSubtitle;

  /// No description provided for @overlayGpsTraces.
  ///
  /// In en, this message translates to:
  /// **'OSM GPS traces'**
  String get overlayGpsTraces;

  /// No description provided for @overlayGpsTracesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Public traces uploaded to OpenStreetMap'**
  String get overlayGpsTracesSubtitle;

  /// No description provided for @overlayNeedsConnection.
  ///
  /// In en, this message translates to:
  /// **'Needs a connection'**
  String get overlayNeedsConnection;

  /// No description provided for @slopeDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Slope from USGS elevation data. Not an avalanche forecast.'**
  String get slopeDisclaimer;

  /// No description provided for @recentWeatherTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent weather'**
  String get recentWeatherTitle;

  /// No description provided for @recentWeatherBody.
  ///
  /// In en, this message translates to:
  /// **'Last 3 days: {rain} rain, {snow} snow, low {temp}'**
  String recentWeatherBody(String rain, String snow, String temp);

  /// No description provided for @recentWeatherNotReport.
  ///
  /// In en, this message translates to:
  /// **'Weather at the trailhead, not a trail report.'**
  String get recentWeatherNotReport;

  /// No description provided for @waypointAdd.
  ///
  /// In en, this message translates to:
  /// **'Add waypoint'**
  String get waypointAdd;

  /// No description provided for @waypointEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit waypoint'**
  String get waypointEdit;

  /// No description provided for @waypointKindWater.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get waypointKindWater;

  /// No description provided for @waypointKindCamp.
  ///
  /// In en, this message translates to:
  /// **'Camp'**
  String get waypointKindCamp;

  /// No description provided for @waypointKindHazard.
  ///
  /// In en, this message translates to:
  /// **'Hazard'**
  String get waypointKindHazard;

  /// No description provided for @waypointKindViewpoint.
  ///
  /// In en, this message translates to:
  /// **'Viewpoint'**
  String get waypointKindViewpoint;

  /// No description provided for @waypointKindParking.
  ///
  /// In en, this message translates to:
  /// **'Parking'**
  String get waypointKindParking;

  /// No description provided for @waypointKindNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get waypointKindNote;

  /// No description provided for @waypointNameHint.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get waypointNameHint;

  /// No description provided for @waypointNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get waypointNoteHint;

  /// No description provided for @waypointAttachToRoute.
  ///
  /// In en, this message translates to:
  /// **'Attach to this route'**
  String get waypointAttachToRoute;

  /// No description provided for @waypointDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete waypoint'**
  String get waypointDelete;

  /// No description provided for @routeDeletePinsToo.
  ///
  /// In en, this message translates to:
  /// **'Also delete pins on this route'**
  String get routeDeletePinsToo;

  /// No description provided for @savedRoutes.
  ///
  /// In en, this message translates to:
  /// **'Routes'**
  String get savedRoutes;

  /// No description provided for @savedTrails.
  ///
  /// In en, this message translates to:
  /// **'Trails'**
  String get savedTrails;

  /// No description provided for @savedOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get savedOffline;

  /// No description provided for @savedEmptyRoutes.
  ///
  /// In en, this message translates to:
  /// **'No saved routes. Draw one in Navigate.'**
  String get savedEmptyRoutes;

  /// No description provided for @savedEmptyTrails.
  ///
  /// In en, this message translates to:
  /// **'No saved trails. Tap the heart on a trail to keep it here.'**
  String get savedEmptyTrails;

  /// No description provided for @activityEmpty.
  ///
  /// In en, this message translates to:
  /// **'No recordings yet.'**
  String get activityEmpty;

  /// No description provided for @activityThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get activityThisMonth;

  /// No description provided for @activityTotals.
  ///
  /// In en, this message translates to:
  /// **'{distance} · {gain} · {count} hikes'**
  String activityTotals(String distance, String gain, int count);

  /// No description provided for @gpxImported.
  ///
  /// In en, this message translates to:
  /// **'{count} imported'**
  String gpxImported(int count);

  /// No description provided for @statEmpty.
  ///
  /// In en, this message translates to:
  /// **'--'**
  String get statEmpty;

  /// No description provided for @attributionIgn.
  ///
  /// In en, this message translates to:
  /// **'© IGN'**
  String get attributionIgn;

  /// No description provided for @attributionNoaa.
  ///
  /// In en, this message translates to:
  /// **'Weather maps: NOAA National Weather Service'**
  String get attributionNoaa;

  /// No description provided for @attributionUsgs3dep.
  ///
  /// In en, this message translates to:
  /// **'Elevation: USGS 3DEP'**
  String get attributionUsgs3dep;

  /// No description provided for @attributionOsmGps.
  ///
  /// In en, this message translates to:
  /// **'GPS traces © OpenStreetMap contributors'**
  String get attributionOsmGps;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
