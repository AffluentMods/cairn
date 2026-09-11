// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// The foreground service that keeps the app alive while recording with the
/// screen off (spec Phase 6). Location is collected on the main isolate and
/// written to the database there; this handler just holds the service and its
/// notification, so it can stay minimal.
@pragma('vm:entry-point')
void startRecordingCallback() {
  FlutterForegroundTask.setTaskHandler(_RecordingTaskHandler());
}

class _RecordingTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp) async {}
}

const _channelId = 'cairn_recording';
const _serviceId = 261;

/// Registers the notification channel. Call once at app start.
void initRecordingService() {
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: _channelId,
      channelName: 'Recording',
      channelImportance: NotificationChannelImportance.LOW,
      priority: NotificationPriority.LOW,
    ),
    iosNotificationOptions: const IOSNotificationOptions(),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.nothing(),
      allowWakeLock: true,
    ),
  );
}

Future<void> startRecordingService(String title, String text) async {
  if (await FlutterForegroundTask.isRunningService) return;
  await FlutterForegroundTask.startService(
    serviceId: _serviceId,
    notificationTitle: title,
    notificationText: text,
    callback: startRecordingCallback,
  );
}

Future<void> updateRecordingNotification(String title, String text) async {
  if (!await FlutterForegroundTask.isRunningService) return;
  await FlutterForegroundTask.updateService(
    notificationTitle: title,
    notificationText: text,
  );
}

Future<void> stopRecordingService() async {
  if (await FlutterForegroundTask.isRunningService) {
    await FlutterForegroundTask.stopService();
  }
}
