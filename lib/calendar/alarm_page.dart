import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'api_service.dart'; // API 호출 함수 import
import 'package:permission_handler/permission_handler.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

// 사용자 시간대 변환
DateTime convertToUserTimeZone(DateTime utcDate, String timeZone) {
  final tz.Location location = tz.getLocation(timeZone);
  final tz.TZDateTime tzDateTime = tz.TZDateTime.from(utcDate, location);
  return tzDateTime.toLocal();
}

// 알림 초기화 함수
Future<void> initializeAlarmNotifications() async {
  tz.initializeTimeZones();
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  final DarwinInitializationSettings initializationSettingsIOS =
  DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
    onDidReceiveLocalNotification: (id, title, body, payload) async {
      print('iOS 포그라운드 알림: title=$title, body=$body');
    },
  );

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (details) {
      print('알림 클릭: ${details.payload}');
    },
  );
}

// 알림 권한 요청
Future<void> requestNotificationPermission() async {
  final status = await Permission.notification.status;

  if (status.isDenied || status.isPermanentlyDenied) {
    final result = await Permission.notification.request();
    if (!result.isGranted) {
      print('알림 권한 거부됨. 앱 설정에서 권한을 허용해주세요.');
      openAppSettings();
    } else {
      print('알림 권한 허용됨.');
    }
  } else {
    print('알림 권한 이미 허용됨.');
  }
}

// 사용자별 알림 예약
Future<void> scheduleUserAlarms(int userNo) async {
  try {
    final alarms = await fetchUserAlarms(userNo);
    for (final alarm in alarms) {
      final title = alarm['user_calendar_name'];
      final body = alarm['user_calendar_memo'] ?? '';
      final repeatType = alarm['user_calendar_every'];
      final timeZone = alarm['user_time_zone'] ?? 'Asia/Seoul';
      final userCalendarDate = DateTime.parse(alarm['user_calendar_date']);
      final userCalendarTime = alarm['user_calendar_time'] ?? '00:00:00';

      final tz.TZDateTime alarmDateTime = makeDateWithTimeZone(
        userCalendarDate,
        userCalendarTime,
        timeZone,
      );

      print('알림 설정: $title | $body | $alarmDateTime');

      if (repeatType == '매일') {
        await scheduleAlarm(alarmDateTime, title, body, 'daily_channel_id', 'Daily Alarm');
      } else if (repeatType == '매주') {
        await scheduleWeeklyAlarm(alarmDateTime, title, body, timeZone);
      } else if (repeatType == '매월') {
        await scheduleMonthlyAlarm(alarmDateTime, title, body, timeZone);
      }
    }
    print('모든 알림 예약 완료');
  } catch (e) {
    print('알림 예약 실패: $e');
  }
}

// 알림 예약 공통 함수
Future<void> scheduleAlarm(
    tz.TZDateTime alarmTime,
    String title,
    String body,
    String channelId,
    String channelName,
    ) async {
  await flutterLocalNotificationsPlugin.zonedSchedule(
    DateTime.now().millisecondsSinceEpoch.remainder(100000),
    title,
    body,
    alarmTime,
    NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        sound: 'default',
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    ),
    androidAllowWhileIdle: true,
    uiLocalNotificationDateInterpretation:
    UILocalNotificationDateInterpretation.absoluteTime,
    matchDateTimeComponents: DateTimeComponents.time,
  );
}

// 매주 알림 예약
Future<void> scheduleWeeklyAlarm(
    tz.TZDateTime alarmDateTime,
    String title,
    String body,
    String timeZone,
    ) async {
  final tz.Location location = tz.getLocation(timeZone);
  tz.TZDateTime alarmTime = alarmDateTime;
  final tz.TZDateTime now = tz.TZDateTime.now(location);

  while (now.isAfter(alarmTime)) {
    alarmTime = alarmTime.add(const Duration(days: 7));
  }

  await scheduleAlarm(alarmTime, title, body, 'weekly_channel_id', 'Weekly Alarm');
}

// 매월 알림 예약
Future<void> scheduleMonthlyAlarm(
    tz.TZDateTime alarmDateTime,
    String title,
    String body,
    String timeZone,
    ) async {
  final tz.Location location = tz.getLocation(timeZone);
  tz.TZDateTime alarmTime = alarmDateTime;
  final tz.TZDateTime now = tz.TZDateTime.now(location);

  while (now.isAfter(alarmTime)) {
    alarmTime = tz.TZDateTime(
      location,
      alarmTime.year,
      alarmTime.month + 1,
      alarmTime.day,
      alarmTime.hour,
      alarmTime.minute,
    );
  }

  await scheduleAlarm(alarmTime, title, body, 'monthly_channel_id', 'Monthly Alarm');
}

// 사용자 시간대 기반 알림 시간 계산
tz.TZDateTime makeDateWithTimeZone(DateTime date, String time, String timeZone) {
  final parts = time.split(':');
  final hour = int.parse(parts[0]);
  final minute = int.parse(parts[1]);
  final tz.Location location = tz.getLocation(timeZone);

  return tz.TZDateTime(
    location,
    date.year,
    date.month,
    date.day,
    hour,
    minute,
  );
}
