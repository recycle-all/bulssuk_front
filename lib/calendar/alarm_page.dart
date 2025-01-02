import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'api_service.dart'; // API 호출 함수 import
import 'package:permission_handler/permission_handler.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

DateTime convertToKST(DateTime utcDate) {
  return utcDate.toLocal().add(const Duration(hours: 9));
}
// 알림 초기화 함수
Future<void> initializeAlarmNotifications() async {
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
  print('알림 권한 요청 중...');

  final status = await Permission.notification.status;

  if (status.isDenied) {
    final result = await Permission.notification.request();
    if (result.isGranted) {
      print('알림 권한 허용됨.');
    } else {
      print('알림 권한 거부됨. 앱 설정에서 권한을 허용해주세요.');
      openAppSettings();
    }
  } else if (status.isPermanentlyDenied) {
    print('알림 권한 영구적으로 거부됨. 앱 설정에서 권한을 허용해야 합니다.');
    openAppSettings();
  } else {
    print('알림 권한 이미 허용됨.');
  }
}

// 사용자별 알림 예약
Future<void> scheduleUserAlarms(int userNo) async {
  try {
    final alarms = await fetchUserAlarms(userNo); // 서버에서 알림 데이터 가져오기
    print("알림테스트");
    print(alarms);
    for (final alarm in alarms) {
      final title = alarm['user_calendar_name'];
      final body = alarm['user_calendar_memo'] ?? '';
      final repeatType = alarm['user_calendar_every'];
      DateTime userCalendarDate = DateTime.parse(alarm['user_calendar_date']);

      // UTC -> KST 변환
      userCalendarDate = convertToKST(userCalendarDate);

      if (repeatType == '매일') {
        await scheduleDailyAlarm(title: title, body: body, startDate: userCalendarDate);
      } else if (repeatType == '매주') {
        await scheduleWeeklyAlarm(title: title, body: body, startDate: userCalendarDate);
      } else if (repeatType == '매월') {
        await scheduleMonthlyAlarm(title: title, body: body, startDate: userCalendarDate);
      }
    }

    print('모든 알림 예약 완료');
  } catch (e) {
    print('알림 예약 실패: $e');
  }
}

// 매일 알림 예약
Future<void> scheduleDailyAlarm({
  required String title,
  required String body,
  required DateTime startDate,
}) async {
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

  final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
  tz.TZDateTime firstAlarmTime = makeDate(startDate, 12, 09);

  if (now.isAfter(firstAlarmTime)) {
    firstAlarmTime = firstAlarmTime.add(const Duration(days: 1));
  }
  // print(firstAlarmTime);
  // print("매일");
  await flutterLocalNotificationsPlugin.zonedSchedule(
    DateTime.now().millisecondsSinceEpoch.remainder(100000), // 고유 ID
    title,
    body,
    firstAlarmTime,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_channel_id',
        'Daily Alarm',
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

  // print('매일 알림 예약 완료: ${firstAlarmTime.toString()}');
}

// 매주 알림 설정
Future<void> scheduleWeeklyAlarm({
  required String title,
  required String body,
  required DateTime startDate,
}) async {
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

  final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
  print(now);
  // `startDate`를 기준으로 알림 시간 생성
  print(startDate);
  final tz.Location seoul = tz.getLocation('Asia/Seoul');
  tz.TZDateTime firstAlarmTime = tz.TZDateTime(
    seoul, // 'Asia/Seoul' 시간대 사용
    startDate.year,
    startDate.month,
    startDate.day,
    12, // 오전 10시
    11, // 30분
  );
  print('초기 알림 시간: $firstAlarmTime');

  if (now.isAfter(firstAlarmTime)) {
    // `firstAlarmTime`이 현재 시간 이후가 될 때까지 7일씩 더함
    while (now.isAfter(firstAlarmTime)) {
      firstAlarmTime = firstAlarmTime.add(const Duration(days: 7));
      print('다음 주 알림 시간 계산: $firstAlarmTime');
    }
  }

  await flutterLocalNotificationsPlugin.zonedSchedule(
    DateTime.now().millisecondsSinceEpoch.remainder(100000), // 고유 ID
    title,
    body,
    firstAlarmTime,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'weekly_channel_id',
        'Weekly Alarm',
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
    matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
  );

  print('매주 알림 예약 완료: $firstAlarmTime');
}

// 매월 알림 설정
Future<void> scheduleMonthlyAlarm({
  required String title,
  required String body,
  required DateTime startDate,
}) async {
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

  final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
  tz.TZDateTime firstAlarmTime = makeDate(startDate, 12, 10); // user_calendar_date 기준
  print(firstAlarmTime);
  // 오늘 날짜에서 시간만 지나지 않았으면 오늘 예약
  if (now.isBefore(firstAlarmTime)) {
    // 오늘 알림 설정
  } else {
    // user_calendar_date가 현재 날짜를 지난 경우 반복 계산
    while (now.isAfter(firstAlarmTime)) {
      firstAlarmTime = tz.TZDateTime(
        tz.local,
        firstAlarmTime.year,
        firstAlarmTime.month + 1,
        startDate.day,
        12,
        10,
      );
    }
  }
  print(firstAlarmTime);
  await flutterLocalNotificationsPlugin.zonedSchedule(
    DateTime.now().millisecondsSinceEpoch.remainder(100000), // 고유 ID
    title,
    body,
    firstAlarmTime,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'monthly_channel_id',
        'Monthly Alarm',
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
    matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime, // 매월 동일 날짜
  );

  print('매월 알림 예약 완료: ${firstAlarmTime.toString()}');
}


// 알림 시간 계산
tz.TZDateTime makeDate(DateTime userCalendarDate, int hour, int minute) {
  final tz.TZDateTime alarmDate = tz.TZDateTime(tz.local, userCalendarDate.year, userCalendarDate.month, userCalendarDate.day, hour, minute);
  return alarmDate;
}

