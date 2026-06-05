import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BubbleStudyApp());
}

class BubbleStudyApp extends StatelessWidget {
  const BubbleStudyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bubble Study',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff0ea5e9)),
        fontFamily: 'Roboto',
      ),
      home: const StudyHomePage(),
    );
  }
}

class StudySession {
  StudySession({
    required this.id,
    required this.startedAt,
    required this.endedAt,
  });

  final String id;
  final DateTime startedAt;
  final DateTime endedAt;

  Duration get duration => endedAt.difference(startedAt);

  bool overlaps(StudySession other) {
    return startedAt.isBefore(other.endedAt) &&
        endedAt.isAfter(other.startedAt);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'startedAt': startedAt.toIso8601String(),
    'endedAt': endedAt.toIso8601String(),
  };

  static StudySession? fromJson(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final startedAt = DateTime.tryParse('${raw['startedAt']}');
    final endedAt = DateTime.tryParse('${raw['endedAt']}');
    if (startedAt == null || endedAt == null || !endedAt.isAfter(startedAt)) {
      return null;
    }
    return StudySession(
      id: '${raw['id'] ?? startedAt.microsecondsSinceEpoch}',
      startedAt: startedAt,
      endedAt: endedAt,
    );
  }
}

enum ImportChoice { local, imported }

enum AppLanguage { zh, en }

enum RestColorRecoveryRate {
  x2_5(2.5),
  x5(5),
  x10(10),
  x20(20),
  x40(40),
  instant(double.infinity);

  const RestColorRecoveryRate(this.multiplier);

  final double multiplier;

  RestColorRecoveryRate get next {
    final values = RestColorRecoveryRate.values;
    return values[(index + 1) % values.length];
  }
}

class AppText {
  const AppText(this.locale);

  final AppLanguage locale;

  bool get isEnglish => locale == AppLanguage.en;

  String get settings => isEnglish ? 'Settings' : '设置';
  String get language => isEnglish ? 'Language' : '语言';
  String get languageBubbleTitle => '语言/Language';
  String get chinese => '简体中文';
  String get english => 'English';
  String get exportRecords => isEnglish ? 'Export study records' : '导出学习记录';
  String get importRecords =>
      isEnglish ? 'Import and merge old data' : '导入并合并旧数据';
  String get viewLogs => isEnglish ? 'Study logs' : '学习日志';
  String get resetBubbleSize => isEnglish ? 'Reset bubble size' : '恢复泡泡默认大小';
  String get targetVibration => isEnglish ? 'Vibrate at 60 min' : '到达60分钟后振动提醒';
  String get restColorRecoveryRate =>
      isEnglish ? 'Rest color recovery' : '休息时间颜色恢复速率';
  String get on => isEnglish ? 'On' : '开';
  String get off => isEnglish ? 'Off' : '关';
  String get clearUserData => isEnglish ? 'Clear all data' : '清除所有数据';
  String get clearUserDataTitle =>
      isEnglish ? 'Clear all user data?' : '清除所有用户数据？';
  String get clearUserDataMessage => isEnglish
      ? 'This will delete study logs and reset settings.'
      : '这会删除学习日志，并重置设置。';
  String get clearUserDataSecondTitle =>
      isEnglish ? 'Final confirmation' : '最后确认';
  String get clearUserDataSecondMessage => isEnglish
      ? 'Really clear all user data? This cannot be undone.'
      : '真的要清除所有用户数据吗？此操作无法撤销。';
  String get clearedUserData =>
      isEnglish ? 'All user data has been cleared.' : '所有用户数据已清除。';
  String get noLogs => isEnglish ? 'No study logs yet' : '还没有学习日志';
  String get edit => isEnglish ? 'Edit' : '编辑';
  String get delete => isEnglish ? 'Delete' : '删除';
  String get cancel => isEnglish ? 'Cancel' : '取消';
  String get save => isEnglish ? 'Save' : '保存';
  String get confirmDelete =>
      isEnglish ? 'Delete this study log?' : '删除这条学习日志？';
  String get start => isEnglish ? 'Start' : '开始';
  String get resting => isEnglish ? 'Resting' : '休息中';
  String get end => isEnglish ? 'End' : '结束';
  String get tapToStudy => isEnglish ? 'Tap to study' : '轻触进入学习';
  String get tapToStartStudy => isEnglish ? 'Tap to start study' : '轻触开始学习';
  String get tapToEnd => isEnglish ? 'Tap to end' : '点击结束';
  String get total => isEnglish ? 'Total' : '累计';
  String get keepLocal => isEnglish ? 'Keep local' : '保留本地';
  String get useImported => isEnglish ? 'Use imported' : '采用导入';
  String get overlapTitle => isEnglish ? 'Overlapping sessions' : '发现重叠时段';
  String get invalidFile => isEnglish
      ? 'This file is not a recognizable study record.'
      : '这个文件不是可识别的学习记录。';
  String get noImportableSessions =>
      isEnglish ? 'No importable study sessions were found.' : '没有找到可导入的学习时段。';
  String get tooShortSkipped => isEnglish
      ? 'Study sessions under 1 minute will not be recorded.'
      : '未满 1 分钟的学习时段将不会被记录';
  String get shareText =>
      isEnglish ? 'Bubble Study records' : 'Bubble Study 学习记录';

  String restColorRecoveryRateLabel(RestColorRecoveryRate rate) {
    return switch (rate) {
      RestColorRecoveryRate.x2_5 => '2.5×',
      RestColorRecoveryRate.x5 => '5×',
      RestColorRecoveryRate.x10 => '10×',
      RestColorRecoveryRate.x20 => '20×',
      RestColorRecoveryRate.x40 => '40×',
      RestColorRecoveryRate.instant => isEnglish ? 'Instant' : '立刻',
    };
  }

  String settingsSummary(int sessions, Duration total) => isEnglish
      ? '$sessions sessions, total ${formatDuration(total)}'
      : '当前共 $sessions 段，累计 ${formatDuration(total)}';

  String sessionCount(int sessions) =>
      isEnglish ? '$sessions sessions' : '$sessions 段学习';

  String importDone(int added, int localKept, int importedKept) => isEnglish
      ? 'Import complete: added $added, kept local $localKept, used imported $importedKept.'
      : '导入完成：新增 $added 段，保留本地 $localKept 段，采用导入 $importedKept 段。';

  String conflictMessage(
    StudySession incoming,
    List<StudySession> conflicts,
    DateFormat format,
  ) {
    final conflictText = conflicts
        .map(
          (session) =>
              '${format.format(session.startedAt)} - ${format.format(session.endedAt)}',
        )
        .join('\n');
    if (isEnglish) {
      return 'Imported:\n${format.format(incoming.startedAt)} - ${format.format(incoming.endedAt)}\n\nLocal overlap:\n$conflictText\n\nChoose which side to keep.';
    }
    return '导入时段：\n${format.format(incoming.startedAt)} - ${format.format(incoming.endedAt)}\n\n本地重叠：\n$conflictText\n\n请选择保留哪一边。';
  }

  String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (isEnglish) {
      if (hours > 0) {
        return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
      }
      return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
    }
    if (hours > 0) {
      return '$hours小时 ${minutes.toString().padLeft(2, '0')}分';
    }
    return '$minutes分 ${seconds.toString().padLeft(2, '0')}秒';
  }

  String formatLargeDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (isEnglish) {
      if (hours > 0) {
        return '${hours}h\n${minutes.toString().padLeft(2, '0')}m';
      }
      return '${minutes.toString().padLeft(2, '0')}m\n${seconds.toString().padLeft(2, '0')}s';
    }
    if (hours > 0) {
      return '$hours小时\n${minutes.toString().padLeft(2, '0')}分钟';
    }
    return '${minutes.toString().padLeft(2, '0')}分钟\n${seconds.toString().padLeft(2, '0')}秒';
  }
}

class StudyHomePage extends StatefulWidget {
  const StudyHomePage({super.key});

  @override
  State<StudyHomePage> createState() => _StudyHomePageState();
}

class _StudyHomePageState extends State<StudyHomePage>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  static const _storageKey = 'study_sessions_v1';
  static const _languageKey = 'app_language_v1';
  static const _bubbleDiameterKey = 'bubble_diameter_v1';
  static const _targetVibrationKey = 'target_vibration_v1';
  static const _activeStartedAtKey = 'active_started_at_v1';
  static const _restColorRecoveryRateKey = 'rest_color_recovery_rate_v1';
  static const _displayStudyProgressKey = 'display_study_progress_v1';
  static const _displayStudyProgressUpdatedAtKey =
      'display_study_progress_updated_at_v1';
  static const _restPromptAllowedKey = 'rest_prompt_allowed_v1';
  static const _targetDuration = Duration(minutes: 60);
  static const _minLogDuration = Duration(minutes: 1);
  static const _tapWindow = Duration(seconds: 3);
  static const _tapSettle = Duration(milliseconds: 320);
  static const _idleFadeDelay = Duration(seconds: 10);
  static const _bubbleNoticeDuration = Duration(milliseconds: 2600);
  static const _bubbleNoticeFadeDuration = Duration(milliseconds: 700);
  static const _defaultBubbleDiameter = 230.0;
  static const _minBubbleDiameter = _defaultBubbleDiameter * 0.5;
  static const _maxBubbleDiameter = _defaultBubbleDiameter * 2;

  final List<StudySession> _sessions = [];
  final DateFormat _fileStamp = DateFormat('yyyyMMdd_HHmmss');
  final DateFormat _humanStamp = DateFormat('yyyy-MM-dd HH:mm');

  late final AnimationController _waveController;
  late final AnimationController _floatController;
  late final AnimationController _backdropFloatController;
  late final AnimationController _flipController;
  late final AnimationController _holdController;
  late final AnimationController _ticker;

  bool _isStudying = false;
  bool _showTotal = false;
  bool _studyLabelVisible = true;
  bool _bubbleNoticeVisible = false;
  bool _restPromptAllowed = false;
  bool _targetVibrationEnabled = false;
  bool _targetVibrationFired = false;
  AppLanguage _language = AppLanguage.zh;
  RestColorRecoveryRate _restColorRecoveryRate = RestColorRecoveryRate.x5;
  String? _bubbleNotice;
  double _displayStudyProgress = 0;
  double _bubbleDiameter = _defaultBubbleDiameter;
  double _targetBubbleDiameter = _defaultBubbleDiameter;
  double? _pinchStartDistance;
  double _pinchStartTargetDiameter = _defaultBubbleDiameter;
  bool _gestureHadPinch = false;
  DateTime? _activeStartedAt;
  DateTime _now = DateTime.now();
  DateTime _lastProgressUpdatedAt = DateTime.now();
  DateTime? _tapBurstStartedAt;
  int _tapBurstCount = 0;
  Timer? _tapActionTimer;
  Timer? _totalAutoFlipTimer;
  Timer? _studyLabelTimer;
  Timer? _bubbleNoticeTimer;
  Timer? _bubbleNoticeClearTimer;
  Timer? _vibrationTimer;
  Offset _swipeDelta = Offset.zero;
  final Map<int, Offset> _activePointers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();
    _backdropFloatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7200),
    )..repeat();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 640),
    );
    _holdController =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              _openSettings();
            }
          });
    _ticker =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..addListener(() {
            if (!mounted) {
              return;
            }
            final now = DateTime.now();
            setState(() {
              _syncTimeBasedState(now);
              _bubbleDiameter = _smoothedBubbleDiameter();
            });
            _maybeTriggerTargetVibration();
          })
          ..repeat();
    _loadState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_saveDisplayStudyProgress());
    _tapActionTimer?.cancel();
    _totalAutoFlipTimer?.cancel();
    _studyLabelTimer?.cancel();
    _bubbleNoticeTimer?.cancel();
    _bubbleNoticeClearTimer?.cancel();
    _vibrationTimer?.cancel();
    WakelockPlus.disable();
    _waveController.dispose();
    _floatController.dispose();
    _backdropFloatController.dispose();
    _flipController.dispose();
    _holdController.dispose();
    _ticker.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      final now = DateTime.now();
      setState(() {
        _syncTimeBasedState(now);
      });
      _maybeTriggerTargetVibration();
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      final now = DateTime.now();
      _syncTimeBasedState(now);
      unawaited(_saveDisplayStudyProgress(at: now));
    }
  }

  AppText get _text => AppText(_language);

  AppLanguage get _systemLanguage {
    final languageCode = WidgetsBinding
        .instance
        .platformDispatcher
        .locale
        .languageCode
        .toLowerCase();
    return languageCode == 'zh' ? AppLanguage.zh : AppLanguage.en;
  }

  double _clampBubbleDiameter(double value) {
    return value.clamp(_minBubbleDiameter, _maxBubbleDiameter).toDouble();
  }

  double _smoothedBubbleDiameter() {
    final delta = _targetBubbleDiameter - _bubbleDiameter;
    if (delta.abs() < 0.05) {
      return _targetBubbleDiameter;
    }
    return _bubbleDiameter + delta * 0.14;
  }

  void _syncTimeBasedState(DateTime now) {
    final elapsed = now.difference(_lastProgressUpdatedAt);
    _lastProgressUpdatedAt = now;
    _now = now;
    _displayStudyProgress = _displayProgressAfterElapsed(
      progress: _displayStudyProgress,
      elapsed: elapsed,
      isStudying: _isStudying,
      recoveryRate: _restColorRecoveryRate,
    );
    if (!_isStudying && _restPromptAllowed && _displayStudyProgress <= 0) {
      _restPromptAllowed = false;
      unawaited(_saveRestPromptAllowed());
    }
  }

  double _displayProgressAfterElapsed({
    required double progress,
    required Duration elapsed,
    required bool isStudying,
    required RestColorRecoveryRate recoveryRate,
  }) {
    final current = progress.clamp(0.0, 1.0).toDouble();
    if (elapsed <= Duration.zero) {
      return current;
    }
    if (isStudying) {
      final step = elapsed.inMilliseconds / _targetDuration.inMilliseconds;
      return math.min(1, current + step);
    }
    if (recoveryRate == RestColorRecoveryRate.instant) {
      return 0;
    }
    final step =
        recoveryRate.multiplier *
        elapsed.inMilliseconds /
        _targetDuration.inMilliseconds;
    return math.max(0, current - step);
  }

  double _restoredDisplayStudyProgress({
    required double? storedProgress,
    required DateTime? storedUpdatedAt,
    required DateTime? activeStartedAt,
    required DateTime now,
    required RestColorRecoveryRate recoveryRate,
  }) {
    final fallback = activeStartedAt == null
        ? 0.0
        : (now.difference(activeStartedAt).inMilliseconds /
                  _targetDuration.inMilliseconds)
              .clamp(0.0, 1.0)
              .toDouble();
    final progress = (storedProgress ?? fallback).clamp(0.0, 1.0).toDouble();
    if (storedUpdatedAt == null) {
      return progress;
    }
    return _displayProgressAfterElapsed(
      progress: progress,
      elapsed: now.difference(storedUpdatedAt),
      isStudying: activeStartedAt != null,
      recoveryRate: recoveryRate,
    );
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final storedLanguage = prefs.getString(_languageKey);
    final stored = prefs.getString(_storageKey);
    final storedActiveStartedAt = DateTime.tryParse(
      prefs.getString(_activeStartedAtKey) ?? '',
    );
    final storedDisplayStudyProgress = prefs.getDouble(
      _displayStudyProgressKey,
    );
    final storedDisplayStudyProgressUpdatedAt = DateTime.tryParse(
      prefs.getString(_displayStudyProgressUpdatedAtKey) ?? '',
    );
    final storedRestPromptAllowed =
        prefs.getBool(_restPromptAllowedKey) ?? false;
    final language = storedLanguage == null
        ? _systemLanguage
        : storedLanguage == AppLanguage.en.name
        ? AppLanguage.en
        : AppLanguage.zh;
    final storedBubbleDiameter = _clampBubbleDiameter(
      prefs.getDouble(_bubbleDiameterKey) ?? _defaultBubbleDiameter,
    );
    final targetVibrationEnabled = prefs.getBool(_targetVibrationKey) ?? false;
    final restColorRecoveryRate = RestColorRecoveryRate.values.firstWhere(
      (item) => item.name == prefs.getString(_restColorRecoveryRateKey),
      orElse: () => RestColorRecoveryRate.x5,
    );
    final restoredActiveStartedAt =
        storedActiveStartedAt != null && storedActiveStartedAt.isBefore(now)
        ? storedActiveStartedAt
        : null;
    final restoredDisplayStudyProgress = _restoredDisplayStudyProgress(
      storedProgress: storedDisplayStudyProgress,
      storedUpdatedAt: storedDisplayStudyProgressUpdatedAt,
      activeStartedAt: restoredActiveStartedAt,
      now: now,
      recoveryRate: restColorRecoveryRate,
    );
    final restoredRestPromptAllowed =
        restoredActiveStartedAt == null &&
        storedRestPromptAllowed &&
        restoredDisplayStudyProgress > 0;
    if (restoredActiveStartedAt != null) {
      await WakelockPlus.enable();
    } else {
      await prefs.remove(_activeStartedAtKey);
    }
    if (stored == null) {
      setState(() {
        _language = language;
        _bubbleDiameter = storedBubbleDiameter;
        _targetBubbleDiameter = storedBubbleDiameter;
        _targetVibrationEnabled = targetVibrationEnabled;
        _restColorRecoveryRate = restColorRecoveryRate;
        _isStudying = restoredActiveStartedAt != null;
        _restPromptAllowed = restoredRestPromptAllowed;
        _activeStartedAt = restoredActiveStartedAt;
        _studyLabelVisible = restoredActiveStartedAt == null;
        _now = now;
        _lastProgressUpdatedAt = now;
        _displayStudyProgress = restoredDisplayStudyProgress;
      });
      if (restoredActiveStartedAt != null) {
        _scheduleStudyLabelFade();
        _maybeTriggerTargetVibration();
      }
      return;
    }
    final decoded = jsonDecode(stored);
    if (decoded is! List) {
      setState(() {
        _language = language;
        _bubbleDiameter = storedBubbleDiameter;
        _targetBubbleDiameter = storedBubbleDiameter;
        _targetVibrationEnabled = targetVibrationEnabled;
        _restColorRecoveryRate = restColorRecoveryRate;
        _isStudying = restoredActiveStartedAt != null;
        _restPromptAllowed = restoredRestPromptAllowed;
        _activeStartedAt = restoredActiveStartedAt;
        _studyLabelVisible = restoredActiveStartedAt == null;
        _now = now;
        _lastProgressUpdatedAt = now;
        _displayStudyProgress = restoredDisplayStudyProgress;
      });
      if (restoredActiveStartedAt != null) {
        _scheduleStudyLabelFade();
        _maybeTriggerTargetVibration();
      }
      return;
    }
    final parsed =
        decoded.map(StudySession.fromJson).whereType<StudySession>().toList()
          ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
    setState(() {
      _language = language;
      _bubbleDiameter = storedBubbleDiameter;
      _targetBubbleDiameter = storedBubbleDiameter;
      _targetVibrationEnabled = targetVibrationEnabled;
      _restColorRecoveryRate = restColorRecoveryRate;
      _isStudying = restoredActiveStartedAt != null;
      _restPromptAllowed = restoredRestPromptAllowed;
      _activeStartedAt = restoredActiveStartedAt;
      _studyLabelVisible = restoredActiveStartedAt == null;
      _now = now;
      _lastProgressUpdatedAt = now;
      _displayStudyProgress = restoredDisplayStudyProgress;
      _sessions
        ..clear()
        ..addAll(parsed);
    });
    if (restoredActiveStartedAt != null) {
      _scheduleStudyLabelFade();
      _maybeTriggerTargetVibration();
    }
  }

  Future<void> _saveSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_sessions.map((item) => item.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  Future<void> _saveDisplayStudyProgress({DateTime? at}) async {
    final prefs = await SharedPreferences.getInstance();
    final savedAt = at ?? DateTime.now();
    await prefs.setDouble(_displayStudyProgressKey, _displayStudyProgress);
    await prefs.setString(
      _displayStudyProgressUpdatedAtKey,
      savedAt.toIso8601String(),
    );
  }

  Future<void> _saveRestPromptAllowed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_restPromptAllowedKey, _restPromptAllowed);
  }

  Future<void> _saveActiveStudy(DateTime startedAt) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeStartedAtKey, startedAt.toIso8601String());
  }

  Future<void> _clearActiveStudy() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeStartedAtKey);
  }

  Future<void> _setLanguage(AppLanguage language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language.name);
    setState(() {
      _language = language;
    });
  }

  Future<void> _saveBubbleDiameter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_bubbleDiameterKey, _targetBubbleDiameter);
  }

  Future<void> _resetBubbleSize() async {
    _activePointers.clear();
    _pinchStartDistance = null;
    setState(() {
      _targetBubbleDiameter = _defaultBubbleDiameter;
    });
    await _saveBubbleDiameter();
  }

  Future<void> _setTargetVibration(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_targetVibrationKey, enabled);
    setState(() {
      _targetVibrationEnabled = enabled;
      if (!enabled) {
        _targetVibrationFired = false;
      }
    });
    if (enabled) {
      _maybeTriggerTargetVibration();
    } else {
      _vibrationTimer?.cancel();
    }
  }

  Future<void> _setRestColorRecoveryRate(
    RestColorRecoveryRate recoveryRate,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    await prefs.setString(_restColorRecoveryRateKey, recoveryRate.name);
    setState(() {
      _syncTimeBasedState(now);
      _restColorRecoveryRate = recoveryRate;
      if (recoveryRate == RestColorRecoveryRate.instant && !_isStudying) {
        _displayStudyProgress = 0;
        _restPromptAllowed = false;
      }
    });
    await _saveDisplayStudyProgress(at: now);
    await _saveRestPromptAllowed();
  }

  void _maybeTriggerTargetVibration() {
    if (!_isStudying ||
        !_targetVibrationEnabled ||
        _targetVibrationFired ||
        _currentDuration < _targetDuration) {
      return;
    }
    _targetVibrationFired = true;
    _runTargetVibration();
  }

  void _runTargetVibration() {
    _vibrationTimer?.cancel();
    var count = 0;
    void pulse() {
      if (!_isStudying || count >= 5) {
        _vibrationTimer?.cancel();
        return;
      }
      HapticFeedback.vibrate();
      count += 1;
      _vibrationTimer = Timer(const Duration(milliseconds: 420), pulse);
    }

    pulse();
  }

  Duration get _totalDuration {
    final saved = _sessions.fold<Duration>(
      Duration.zero,
      (total, session) => total + session.duration,
    );
    final active = _isStudying && _activeStartedAt != null
        ? _now.difference(_activeStartedAt!)
        : Duration.zero;
    return saved + active;
  }

  Duration get _currentDuration {
    if (!_isStudying || _activeStartedAt == null) {
      return Duration.zero;
    }
    return _now.difference(_activeStartedAt!);
  }

  Future<void> _toggleStudy() async {
    if (_isStudying) {
      final startedAt = _activeStartedAt;
      if (startedAt == null) {
        return;
      }
      final endedAt = DateTime.now();
      _syncTimeBasedState(endedAt);
      final duration = endedAt.difference(startedAt);
      final isRecordable = duration >= _minLogDuration;
      if (isRecordable) {
        _sessions.add(
          StudySession(
            id: endedAt.microsecondsSinceEpoch.toString(),
            startedAt: startedAt,
            endedAt: endedAt,
          ),
        );
        _sessions.sort((a, b) => a.startedAt.compareTo(b.startedAt));
        await _saveSessions();
      } else {
        _showBubbleNotice(_text.tooShortSkipped);
      }
      await _clearActiveStudy();
      await WakelockPlus.disable();
      _studyLabelTimer?.cancel();
      _vibrationTimer?.cancel();
      setState(() {
        _isStudying = false;
        _restPromptAllowed =
            isRecordable &&
            _restColorRecoveryRate != RestColorRecoveryRate.instant &&
            _displayStudyProgress > 0;
        _activeStartedAt = null;
        _studyLabelVisible = _bubbleNotice == null;
        _targetVibrationFired = false;
        if (_restColorRecoveryRate == RestColorRecoveryRate.instant) {
          _displayStudyProgress = 0;
        }
      });
      await _saveDisplayStudyProgress(at: endedAt);
      await _saveRestPromptAllowed();
    } else {
      final startedAt = DateTime.now();
      _syncTimeBasedState(startedAt);
      await _saveActiveStudy(startedAt);
      await WakelockPlus.enable();
      setState(() {
        _isStudying = true;
        _restPromptAllowed = false;
        _activeStartedAt = startedAt;
        _now = startedAt;
        _studyLabelVisible = true;
        _bubbleNoticeVisible = false;
        _bubbleNotice = null;
        _targetVibrationFired = false;
      });
      await _saveDisplayStudyProgress(at: startedAt);
      await _saveRestPromptAllowed();
      _scheduleStudyLabelFade();
    }
    _waveController.forward(from: 0);
  }

  void _scheduleStudyLabelFade() {
    _studyLabelTimer?.cancel();
    if (!_isStudying) {
      return;
    }
    _studyLabelTimer = Timer(_idleFadeDelay, () {
      if (!mounted || !_isStudying) {
        return;
      }
      setState(() {
        _studyLabelVisible = false;
      });
    });
  }

  void _revealStudyLabel() {
    if (!_isStudying) {
      return;
    }
    setState(() {
      _studyLabelVisible = true;
    });
    _scheduleStudyLabelFade();
  }

  void _hideStudyLabelNow() {
    if (!_isStudying || !_studyLabelVisible) {
      return;
    }
    _studyLabelTimer?.cancel();
    setState(() {
      _studyLabelVisible = false;
    });
  }

  void _handleBackdropTap() {
    _hideStudyLabelNow();
  }

  void _scheduleTotalAutoFlip() {
    _totalAutoFlipTimer?.cancel();
    if (!_showTotal) {
      return;
    }
    _totalAutoFlipTimer = Timer(_idleFadeDelay, () {
      if (!mounted || !_showTotal) {
        return;
      }
      setState(() {
        _showTotal = false;
      });
      _flipController.reverse();
    });
  }

  void _showBubbleNotice(String message) {
    _bubbleNoticeTimer?.cancel();
    _bubbleNoticeClearTimer?.cancel();
    setState(() {
      _bubbleNotice = message;
      _bubbleNoticeVisible = true;
      _studyLabelVisible = false;
    });
    _bubbleNoticeTimer = Timer(_bubbleNoticeDuration, () {
      if (!mounted) {
        return;
      }
      setState(() {
        _bubbleNoticeVisible = false;
      });
      _bubbleNoticeClearTimer = Timer(_bubbleNoticeFadeDuration, () {
        if (!mounted) {
          return;
        }
        setState(() {
          _bubbleNotice = null;
          _studyLabelVisible = true;
        });
      });
    });
  }

  void _handleSettledTap() {
    if (_showTotal) {
      _scheduleTotalAutoFlip();
      return;
    }
    if (_isStudying && !_studyLabelVisible) {
      _revealStudyLabel();
      return;
    }
    _toggleStudy();
  }

  void _handleTap() {
    if (_gestureHadPinch) {
      _gestureHadPinch = false;
      return;
    }
    final now = DateTime.now();
    if (_tapBurstStartedAt == null ||
        now.difference(_tapBurstStartedAt!) > _tapWindow) {
      _tapBurstStartedAt = now;
      _tapBurstCount = 1;
    } else {
      _tapBurstCount += 1;
    }

    _tapActionTimer?.cancel();
    if (_tapBurstCount >= 5) {
      _tapBurstCount = 0;
      _tapBurstStartedAt = null;
      _openSettings();
      return;
    }

    _tapActionTimer = Timer(_tapSettle, () {
      _tapBurstCount = 0;
      _tapBurstStartedAt = null;
      _handleSettledTap();
    });
  }

  void _startHold() {
    _holdController.forward(from: 0);
  }

  void _cancelHold() {
    if (_holdController.status != AnimationStatus.completed) {
      _holdController.reset();
    }
  }

  void _toggleTotal() {
    setState(() {
      _showTotal = !_showTotal;
    });
    if (_showTotal) {
      _flipController.forward();
      _scheduleTotalAutoFlip();
    } else {
      _totalAutoFlipTimer?.cancel();
      _flipController.reverse();
    }
  }

  void _beginFlipSwipe() {
    if (_showTotal) {
      _scheduleTotalAutoFlip();
    }
    _swipeDelta = Offset.zero;
  }

  void _trackFlipSwipe(DragUpdateDetails details) {
    if (_activePointers.length > 1) {
      return;
    }
    _swipeDelta += details.delta;
  }

  double? _currentPinchDistance() {
    if (_activePointers.length < 2) {
      return null;
    }
    final points = _activePointers.values.take(2).toList();
    return (points[0] - points[1]).distance;
  }

  void _startPinchIfReady() {
    final distance = _currentPinchDistance();
    if (distance == null) {
      return;
    }
    _pinchStartDistance = distance;
    _pinchStartTargetDiameter = _targetBubbleDiameter;
  }

  void _handleBubblePointerDown(PointerDownEvent event) {
    _activePointers[event.pointer] = event.localPosition;
    if (_activePointers.length == 2) {
      _gestureHadPinch = true;
      _swipeDelta = Offset.zero;
      _startPinchIfReady();
    }
  }

  void _handleBubblePointerMove(PointerMoveEvent event) {
    if (!_activePointers.containsKey(event.pointer)) {
      return;
    }
    _activePointers[event.pointer] = event.localPosition;
    final startDistance = _pinchStartDistance;
    final currentDistance = _currentPinchDistance();
    if (startDistance == null || currentDistance == null) {
      return;
    }
    final fingerDelta = currentDistance - startDistance;
    final target = _pinchStartTargetDiameter + fingerDelta / 10;
    setState(() {
      _targetBubbleDiameter = _clampBubbleDiameter(target);
    });
  }

  void _handleBubblePointerEnd(PointerEvent event) {
    _activePointers.remove(event.pointer);
    if (_activePointers.length >= 2) {
      _startPinchIfReady();
    } else {
      _pinchStartDistance = null;
    }
    _saveBubbleDiameter();
  }

  void _endFlipSwipe() {
    if (_activePointers.length > 1 || _gestureHadPinch) {
      _swipeDelta = Offset.zero;
      _gestureHadPinch = false;
      return;
    }
    final dx = _swipeDelta.dx.abs();
    final dy = _swipeDelta.dy.abs();
    _swipeDelta = Offset.zero;
    if (dx < 58 || dy < 58) {
      return;
    }
    final diagonalBalance = dx / dy;
    if (diagonalBalance < 0.35 || diagonalBalance > 2.85) {
      if (_showTotal) {
        _scheduleTotalAutoFlip();
      }
      return;
    }
    _toggleTotal();
  }

  Future<void> _openSettings() async {
    _holdController.reset();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: const Color(0xfff8fafc),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, refreshSettings) {
            final text = _text;
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      text.settings,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xff0f172a),
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        const spacing = 12.0;
                        const targetCellWidth = 156.0;
                        final columns =
                            ((constraints.maxWidth + spacing) /
                                    (targetCellWidth + spacing))
                                .floor()
                                .clamp(2, 5);
                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: columns,
                          mainAxisSpacing: spacing,
                          crossAxisSpacing: spacing,
                          childAspectRatio: 1.18,
                          children: [
                            _SettingsBubbleButton(
                              icon: Icons.language_outlined,
                              label: text.languageBubbleTitle,
                              value: _language == AppLanguage.zh
                                  ? text.chinese
                                  : text.english,
                              selected: true,
                              onPressed: () async {
                                await _setLanguage(
                                  _language == AppLanguage.zh
                                      ? AppLanguage.en
                                      : AppLanguage.zh,
                                );
                                refreshSettings(() {});
                              },
                            ),
                            _SettingsBubbleButton(
                              icon: Icons.history_outlined,
                              label: text.viewLogs,
                              onPressed: _openLogs,
                            ),
                            _SettingsBubbleButton(
                              icon: Icons.file_upload_outlined,
                              label: text.exportRecords,
                              onPressed: _exportSessions,
                            ),
                            _SettingsBubbleButton(
                              icon: Icons.file_download_outlined,
                              label: text.importRecords,
                              onPressed: _importSessions,
                            ),
                            _SettingsBubbleButton(
                              icon: Icons.center_focus_strong_outlined,
                              label: text.resetBubbleSize,
                              onPressed: () async {
                                await _resetBubbleSize();
                                refreshSettings(() {});
                              },
                            ),
                            _SettingsBubbleButton(
                              icon: Icons.vibration,
                              label: text.targetVibration,
                              value: _targetVibrationEnabled
                                  ? text.on
                                  : text.off,
                              selected: _targetVibrationEnabled,
                              onPressed: () async {
                                await _setTargetVibration(
                                  !_targetVibrationEnabled,
                                );
                                refreshSettings(() {});
                              },
                            ),
                            _SettingsBubbleButton(
                              icon: Icons.hourglass_bottom_outlined,
                              label: text.restColorRecoveryRate,
                              value: text.restColorRecoveryRateLabel(
                                _restColorRecoveryRate,
                              ),
                              selected: true,
                              onPressed: () async {
                                await _setRestColorRecoveryRate(
                                  _restColorRecoveryRate.next,
                                );
                                refreshSettings(() {});
                              },
                            ),
                            _SettingsBubbleButton(
                              icon: Icons.delete_forever_outlined,
                              label: text.clearUserData,
                              danger: true,
                              onPressed: _clearUserData,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    Text(
                      text.settingsSummary(_sessions.length, _totalDuration),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xff64748b),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _clearUserData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final text = _text;
        return AlertDialog(
          title: Text(text.clearUserDataTitle),
          content: Text(text.clearUserDataMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(text.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(text.delete),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }
    if (!mounted) {
      return;
    }
    final secondConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final text = _text;
        return AlertDialog(
          title: Text(text.clearUserDataSecondTitle),
          content: Text(text.clearUserDataSecondMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(text.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(text.delete),
            ),
          ],
        );
      },
    );
    if (secondConfirmed != true) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await WakelockPlus.disable();
    await prefs.remove(_storageKey);
    await prefs.remove(_languageKey);
    await prefs.remove(_bubbleDiameterKey);
    await prefs.remove(_targetVibrationKey);
    await prefs.remove(_activeStartedAtKey);
    await prefs.remove(_restColorRecoveryRateKey);
    await prefs.remove(_displayStudyProgressKey);
    await prefs.remove(_displayStudyProgressUpdatedAtKey);
    await prefs.remove(_restPromptAllowedKey);
    if (!mounted) {
      return;
    }
    setState(() {
      _sessions.clear();
      _language = _systemLanguage;
      _isStudying = false;
      _restPromptAllowed = false;
      _activeStartedAt = null;
      _now = DateTime.now();
      _showTotal = false;
      _studyLabelVisible = true;
      _bubbleNoticeVisible = false;
      _bubbleNotice = null;
      _bubbleDiameter = _defaultBubbleDiameter;
      _targetBubbleDiameter = _defaultBubbleDiameter;
      _targetVibrationEnabled = false;
      _targetVibrationFired = false;
      _restColorRecoveryRate = RestColorRecoveryRate.x5;
      _displayStudyProgress = 0;
    });
    _totalAutoFlipTimer?.cancel();
    _studyLabelTimer?.cancel();
    _bubbleNoticeTimer?.cancel();
    _bubbleNoticeClearTimer?.cancel();
    _vibrationTimer?.cancel();
    _flipController.reverse();
    _showSnack(_text.clearedUserData);
  }

  Future<void> _exportSessions() async {
    final directory = await getTemporaryDirectory();
    final file = File(
      '${directory.path}${Platform.pathSeparator}bubble_study_${_fileStamp.format(DateTime.now())}.json',
    );
    final payload = {
      'schema': 'bubble_study.sessions.v1',
      'exportedAt': DateTime.now().toIso8601String(),
      'sessions': _sessions.map((session) => session.toJson()).toList(),
    };
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
    );
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: _text.shareText),
    );
  }

  Future<void> _importSessions() async {
    const jsonType = XTypeGroup(label: 'JSON', extensions: ['json']);
    final result = await openFile(acceptedTypeGroups: [jsonType]);
    if (result == null) {
      return;
    }
    final file = File(result.path);
    final raw = await file.readAsString();
    final decoded = jsonDecode(raw);
    final rawSessions = decoded is Map ? decoded['sessions'] : decoded;
    if (rawSessions is! List) {
      _showSnack(_text.invalidFile);
      return;
    }
    final imported = rawSessions
        .map(StudySession.fromJson)
        .whereType<StudySession>()
        .toList();
    if (imported.isEmpty) {
      _showSnack(_text.noImportableSessions);
      return;
    }

    final merged = [..._sessions];
    var importedAdded = 0;
    var localKept = 0;
    var importedKept = 0;

    for (final incoming in imported) {
      final conflicts = merged
          .where((local) => local.overlaps(incoming))
          .toList();
      if (conflicts.isEmpty) {
        merged.add(incoming);
        importedAdded += 1;
        continue;
      }

      final choice = await _askConflictChoice(incoming, conflicts);
      if (choice == ImportChoice.imported) {
        merged.removeWhere((local) => conflicts.contains(local));
        merged.add(incoming);
        importedKept += 1;
      } else {
        localKept += 1;
      }
    }

    merged.sort((a, b) => a.startedAt.compareTo(b.startedAt));
    setState(() {
      _sessions
        ..clear()
        ..addAll(merged);
    });
    await _saveSessions();
    _showSnack(_text.importDone(importedAdded, localKept, importedKept));
  }

  Future<ImportChoice> _askConflictChoice(
    StudySession incoming,
    List<StudySession> conflicts,
  ) async {
    return await showDialog<ImportChoice>(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              title: Text(_text.overlapTitle),
              content: Text(
                _text.conflictMessage(incoming, conflicts, _humanStamp),
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.of(context).pop(ImportChoice.local),
                  child: Text(_text.keepLocal),
                ),
                FilledButton(
                  onPressed: () =>
                      Navigator.of(context).pop(ImportChoice.imported),
                  child: Text(_text.useImported),
                ),
              ],
            );
          },
        ) ??
        ImportChoice.local;
  }

  Future<void> _openLogs() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: const Color(0xfff8fafc),
      builder: (context) {
        final text = _text;
        final sessions = [..._sessions.reversed];
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.78,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
              child: Column(
                children: [
                  Text(
                    text.viewLogs,
                    style: const TextStyle(
                      color: Color(0xff0f172a),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: sessions.isEmpty
                        ? Center(
                            child: Text(
                              text.noLogs,
                              style: const TextStyle(color: Color(0xff64748b)),
                            ),
                          )
                        : ListView.separated(
                            itemCount: sessions.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final session = sessions[index];
                              return _LogTile(
                                session: session,
                                text: text,
                                format: _humanStamp,
                                onTap: () => _openLogEditor(session),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openLogEditor(StudySession session) async {
    final startController = TextEditingController(
      text: _humanStamp.format(session.startedAt),
    );
    final endController = TextEditingController(
      text: _humanStamp.format(session.endedAt),
    );
    await showDialog<void>(
      context: context,
      builder: (context) {
        final text = _text;
        return AlertDialog(
          title: Text(text.edit),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: startController,
                decoration: InputDecoration(
                  labelText: text.isEnglish ? 'Start time' : '开始时间',
                  hintText: 'yyyy-MM-dd HH:mm',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: endController,
                decoration: InputDecoration(
                  labelText: text.isEnglish ? 'End time' : '结束时间',
                  hintText: 'yyyy-MM-dd HH:mm',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteSession(session);
              },
              child: Text(text.delete),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(text.cancel),
            ),
            FilledButton(
              onPressed: () async {
                final startedAt = _parseHumanDate(startController.text);
                final endedAt = _parseHumanDate(endController.text);
                if (startedAt == null ||
                    endedAt == null ||
                    !endedAt.isAfter(startedAt)) {
                  _showSnack(text.invalidFile);
                  return;
                }
                final navigator = Navigator.of(context);
                await _updateSession(session, startedAt, endedAt);
                navigator.pop();
              },
              child: Text(text.save),
            ),
          ],
        );
      },
    );
    startController.dispose();
    endController.dispose();
  }

  DateTime? _parseHumanDate(String value) {
    try {
      return _humanStamp.parseStrict(value.trim());
    } catch (_) {
      return null;
    }
  }

  Future<void> _updateSession(
    StudySession session,
    DateTime startedAt,
    DateTime endedAt,
  ) async {
    setState(() {
      final index = _sessions.indexWhere((item) => item.id == session.id);
      if (index >= 0) {
        _sessions[index] = StudySession(
          id: session.id,
          startedAt: startedAt,
          endedAt: endedAt,
        );
        _sessions.sort((a, b) => a.startedAt.compareTo(b.startedAt));
      }
    });
    await _saveSessions();
  }

  Future<void> _deleteSession(StudySession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final text = _text;
        return AlertDialog(
          title: Text(text.confirmDelete),
          content: Text(
            '${_humanStamp.format(session.startedAt)} - ${_humanStamp.format(session.endedAt)}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(text.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(text.delete),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }
    setState(() {
      _sessions.removeWhere((item) => item.id == session.id);
    });
    await _saveSessions();
  }

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = _paletteForProgress(_displayStudyProgress);
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleBackdropTap,
        onPanStart: (_) => _beginFlipSwipe(),
        onPanUpdate: _trackFlipSwipe,
        onPanEnd: (_) => _endFlipSwipe(),
        onPanCancel: () => _swipeDelta = Offset.zero,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _waveController,
            _floatController,
            _backdropFloatController,
            _flipController,
            _holdController,
            _ticker,
          ]),
          builder: (context, _) {
            return CustomPaint(
              painter: OceanBackdropPainter(
                palette: palette,
                waveProgress: _waveController.value,
                isStudying: _isStudying,
                drift: _backdropFloatController.value,
              ),
              child: SafeArea(
                child: Center(
                  child: Listener(
                    onPointerDown: _handleBubblePointerDown,
                    onPointerMove: _handleBubblePointerMove,
                    onPointerUp: _handleBubblePointerEnd,
                    onPointerCancel: _handleBubblePointerEnd,
                    child: GestureDetector(
                      onTap: _handleTap,
                      onLongPressStart: (_) => _startHold(),
                      onLongPressEnd: (_) => _cancelHold(),
                      onLongPressCancel: _cancelHold,
                      child: Transform.translate(
                        offset: Offset(
                          math.sin(_floatController.value * math.pi * 2) * 7,
                          math.cos(_floatController.value * math.pi * 2) * 10,
                        ),
                        child: StudyBubbleButton(
                          diameter: _bubbleDiameter,
                          flip: _flipController.value,
                          hold: _holdController.value,
                          phase: _floatController.value,
                          text: _text,
                          isStudying: _isStudying,
                          isResting: _restPromptAllowed,
                          studyLabelVisible: _studyLabelVisible,
                          bubbleNotice: _bubbleNotice,
                          bubbleNoticeVisible: _bubbleNoticeVisible,
                          currentDuration: _currentDuration,
                          totalDuration: _totalDuration,
                          sessions: _sessions.length,
                          progress: _displayStudyProgress,
                          fontScale: (_bubbleDiameter / _defaultBubbleDiameter)
                              .clamp(0.5, 2.0)
                              .toDouble(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class StudyBubbleButton extends StatelessWidget {
  const StudyBubbleButton({
    super.key,
    required this.diameter,
    required this.flip,
    required this.hold,
    required this.phase,
    required this.text,
    required this.isStudying,
    required this.isResting,
    required this.studyLabelVisible,
    required this.bubbleNotice,
    required this.bubbleNoticeVisible,
    required this.currentDuration,
    required this.totalDuration,
    required this.sessions,
    required this.progress,
    required this.fontScale,
  });

  final double diameter;
  final double flip;
  final double hold;
  final double phase;
  final AppText text;
  final bool isStudying;
  final bool isResting;
  final bool studyLabelVisible;
  final String? bubbleNotice;
  final bool bubbleNoticeVisible;
  final Duration currentDuration;
  final Duration totalDuration;
  final int sessions;
  final double progress;
  final double fontScale;

  @override
  Widget build(BuildContext context) {
    final lockedFontScale = fontScale.clamp(0.5, 2.0).toDouble();
    final compression = math.sin(flip * math.pi);
    final xScale = 1 - compression * 0.68;
    final yScale = 1 + compression * 0.08;
    final frontOpacity = (1 - (flip * 2).clamp(0.0, 1.0)).toDouble();
    final backOpacity = ((flip - 0.5) * 2).clamp(0.0, 1.0).toDouble();
    return Transform.scale(
      alignment: Alignment.center,
      scaleX: xScale,
      scaleY: yScale,
      child: SizedBox(
        width: diameter,
        height: diameter,
        child: CustomPaint(
          painter: BubblePainter(
            progress: progress,
            hold: hold,
            phase: phase,
            compression: compression,
          ),
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 720),
                  curve: Curves.easeOutCubic,
                  opacity: frontOpacity * (studyLabelVisible ? 1 : 0),
                  child: _BubbleFront(
                    isStudying: isStudying,
                    isResting: isResting,
                    currentDuration: currentDuration,
                    text: text,
                    fontScale: lockedFontScale,
                  ),
                ),
                Opacity(
                  opacity: backOpacity,
                  child: _BubbleBack(
                    totalDuration: totalDuration,
                    sessions: sessions,
                    text: text,
                    fontScale: lockedFontScale,
                  ),
                ),
                Positioned(
                  left: -42 * lockedFontScale,
                  right: -42 * lockedFontScale,
                  bottom: 30 * lockedFontScale,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 520),
                    curve: Curves.easeOutCubic,
                    opacity: frontOpacity * (bubbleNoticeVisible ? 1 : 0),
                    child: _BubbleNotice(
                      message: bubbleNotice ?? '',
                      fontScale: lockedFontScale,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BubbleNotice extends StatelessWidget {
  const _BubbleNotice({required this.message, required this.fontScale});

  final String message;
  final double fontScale;

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withNoTextScaling(
      child: Text(
        message,
        textAlign: TextAlign.center,
        maxLines: 3,
        overflow: TextOverflow.visible,
        softWrap: true,
        style: TextStyle(
          color: const Color(0xf2ffffff),
          fontSize: 19 * fontScale,
          fontWeight: FontWeight.w800,
          height: 1.2,
          shadows: const [
            Shadow(
              color: Color(0x66003664),
              offset: Offset(0, 2),
              blurRadius: 14,
            ),
          ],
        ),
      ),
    );
  }
}

class _BubbleFront extends StatelessWidget {
  const _BubbleFront({
    required this.isStudying,
    required this.isResting,
    required this.currentDuration,
    required this.text,
    required this.fontScale,
  });

  final bool isStudying;
  final bool isResting;
  final Duration currentDuration;
  final AppText text;
  final double fontScale;

  @override
  Widget build(BuildContext context) {
    final primaryText = isStudying
        ? _smallDuration(currentDuration)
        : isResting
        ? text.resting
        : text.start;
    final secondaryText = isStudying
        ? text.tapToEnd
        : isResting
        ? text.tapToStartStudy
        : text.tapToStudy;
    final primarySize = (isStudying ? 38.0 : 44.0) * fontScale;
    final secondarySize = (isStudying ? 15.0 : 16.0) * fontScale;
    final labelMode = isStudying
        ? 'studying'
        : isResting
        ? 'resting'
        : 'idle';

    return MediaQuery.withNoTextScaling(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 680),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: Column(
          key: ValueKey(labelMode),
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              primaryText,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: primarySize,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
                height: 1.02,
                shadows: const [
                  Shadow(
                    color: Color(0x66003664),
                    offset: Offset(0, 2),
                    blurRadius: 16,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              secondaryText,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xddffffff),
                fontSize: secondarySize,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BubbleBack extends StatelessWidget {
  const _BubbleBack({
    required this.totalDuration,
    required this.sessions,
    required this.text,
    required this.fontScale,
  });

  final Duration totalDuration;
  final int sessions;
  final AppText text;
  final double fontScale;

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withNoTextScaling(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text.total,
            style: TextStyle(
              color: const Color(0xeeffffff),
              fontSize: 19 * fontScale,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            text.formatLargeDuration(totalDuration),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 32 * fontScale,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
              height: 1.08,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            text.sessionCount(sessions),
            style: TextStyle(
              color: const Color(0xdfffffff),
              fontSize: 15 * fontScale,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({
    required this.session,
    required this.text,
    required this.format,
    required this.onTap,
  });

  final StudySession session;
  final AppText text;
  final DateFormat format;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text(
          '${format.format(session.startedAt)} - ${format.format(session.endedAt)}',
          style: const TextStyle(
            color: Color(0xff0f172a),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          text.formatDuration(session.duration),
          style: const TextStyle(color: Color(0xff64748b), fontSize: 13),
        ),
        trailing: const Icon(Icons.chevron_right, color: Color(0xff64748b)),
      ),
    );
  }
}

class _SettingsBubbleButton extends StatelessWidget {
  const _SettingsBubbleButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.value,
    this.danger = false,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final String? value;
  final bool danger;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return _FloatingSettingsBubbleButton(
      icon: icon,
      label: label,
      value: value,
      danger: danger,
      selected: selected,
      onPressed: onPressed,
    );
  }
}

class _FloatingSettingsBubbleButton extends StatefulWidget {
  const _FloatingSettingsBubbleButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.value,
    this.danger = false,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final String? value;
  final bool danger;
  final bool selected;

  @override
  State<_FloatingSettingsBubbleButton> createState() =>
      _FloatingSettingsBubbleButtonState();
}

class _FloatingSettingsBubbleButtonState
    extends State<_FloatingSettingsBubbleButton>
    with TickerProviderStateMixin {
  late final AnimationController _floatController;
  late final AnimationController _flipController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    _flipController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.value != null) {
      _flipController.forward(from: 0);
      Timer(const Duration(milliseconds: 160), () {
        if (!mounted) {
          return;
        }
        widget.onPressed();
      });
      return;
    }
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final seed = widget.label.hashCode.abs() % 1000 / 1000.0;
    return AnimatedBuilder(
      animation: Listenable.merge([_floatController, _flipController]),
      builder: (context, child) {
        final phase = (_floatController.value + seed) * math.pi * 2;
        final flip = math.sin(_flipController.value * math.pi);
        return Transform.translate(
          offset: Offset(math.sin(phase) * 2.2, math.cos(phase) * 3.0),
          child: Transform.scale(
            scaleX: 1 - flip * 0.42,
            scaleY: 1 + flip * 0.10,
            child: child,
          ),
        );
      },
      child: _SettingsBubbleSurface(
        icon: widget.icon,
        label: widget.label,
        value: widget.value,
        danger: widget.danger,
        selected: widget.selected,
        onTap: _handleTap,
      ),
    );
  }
}

class _SettingsBubbleSurface extends StatelessWidget {
  const _SettingsBubbleSurface({
    required this.icon,
    required this.label,
    required this.onTap,
    this.value,
    this.danger = false,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;
  final bool danger;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = danger
        ? [
            const Color(0xffffb4b4),
            const Color(0xffef4444),
            const Color(0xff7f1d1d),
          ]
        : selected
        ? [
            const Color(0xffd9f99d),
            const Color(0xff22d3ee),
            const Color(0xff0f766e),
          ]
        : [
            const Color(0xffe0f7ff),
            const Color(0xff67e8f9),
            const Color(0xff0ea5e9),
          ];
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AspectRatio(
          aspectRatio: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.42, -0.48),
                radius: 1.08,
                colors: colors,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.last.withValues(alpha: danger ? 0.26 : 0.22),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: selected ? 0.92 : 0.52),
                width: selected ? 2.2 : 1.4,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 27),
                  const SizedBox(height: 8),
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: value == null ? 3 : 2,
                      overflow: TextOverflow.visible,
                      softWrap: true,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        height: 1.12,
                        shadows: [
                          Shadow(
                            color: Color(0x66003664),
                            offset: Offset(0, 2),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (value != null) ...[
                    const SizedBox(height: 6),
                    Flexible(
                      child: Text(
                        value!,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.visible,
                        softWrap: true,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          height: 1,
                          shadows: [
                            Shadow(
                              color: Color(0x66003664),
                              offset: Offset(0, 2),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class StudyPalette {
  const StudyPalette(this.top, this.middle, this.bottom, this.accent);

  final Color top;
  final Color middle;
  final Color bottom;
  final Color accent;
}

class _BubbleColorStop {
  const _BubbleColorStop(this.progress, this.colors);

  final double progress;
  final List<Color> colors;
}

const _initialBubbleColors = [
  Color(0xff7dd3fc),
  Color(0xff22d3ee),
  Color(0xff075985),
];

List<Color> _bubbleColorsForProgress(double progress) {
  const stops = [
    _BubbleColorStop(0.0, _initialBubbleColors),
    _BubbleColorStop(0.36, [
      Color(0xffd9f99d),
      Color(0xff84cc16),
      Color(0xff166534),
    ]),
    _BubbleColorStop(0.65, [
      Color(0xffffd166),
      Color(0xfff97316),
      Color(0xff9a3412),
    ]),
    _BubbleColorStop(1.0, [
      Color(0xffff9aa2),
      Color(0xffef4444),
      Color(0xff7f1d1d),
    ]),
  ];

  final p = progress.clamp(0.0, 1.0);
  for (var i = 0; i < stops.length - 1; i += 1) {
    final start = stops[i];
    final end = stops[i + 1];
    if (p <= end.progress) {
      final t = ((p - start.progress) / (end.progress - start.progress))
          .toDouble();
      return [
        Color.lerp(start.colors[0], end.colors[0], t)!,
        Color.lerp(start.colors[1], end.colors[1], t)!,
        Color.lerp(start.colors[2], end.colors[2], t)!,
      ];
    }
  }
  return stops.last.colors;
}

StudyPalette _paletteForProgress(double progress) {
  const stops = [
    StudyPalette(
      Color(0xff083d77),
      Color(0xff0ea5e9),
      Color(0xff67e8f9),
      Color(0xffb6f3ff),
    ),
    StudyPalette(
      Color(0xff064e3b),
      Color(0xff10b981),
      Color(0xffbef264),
      Color(0xffd9f99d),
    ),
    StudyPalette(
      Color(0xff365314),
      Color(0xff84cc16),
      Color(0xfffacc15),
      Color(0xfffde68a),
    ),
    StudyPalette(
      Color(0xff7c2d12),
      Color(0xfff97316),
      Color(0xffffc857),
      Color(0xffffedd5),
    ),
    StudyPalette(
      Color(0xff450a0a),
      Color(0xffdc2626),
      Color(0xfffb7185),
      Color(0xffffd6d6),
    ),
  ];

  final scaled = progress.clamp(0.0, 1.0) * (stops.length - 1);
  final index = scaled.floor().clamp(0, stops.length - 2);
  final t = scaled - index;
  final vivid = StudyPalette(
    Color.lerp(stops[index].top, stops[index + 1].top, t)!,
    Color.lerp(stops[index].middle, stops[index + 1].middle, t)!,
    Color.lerp(stops[index].bottom, stops[index + 1].bottom, t)!,
    Color.lerp(stops[index].accent, stops[index + 1].accent, t)!,
  );
  final base = stops.first;
  const backdropStrength = 0.68;
  return StudyPalette(
    Color.lerp(base.top, vivid.top, backdropStrength)!,
    Color.lerp(base.middle, vivid.middle, backdropStrength)!,
    Color.lerp(base.bottom, vivid.bottom, backdropStrength)!,
    Color.lerp(base.accent, vivid.accent, 0.78)!,
  );
}

class OceanBackdropPainter extends CustomPainter {
  OceanBackdropPainter({
    required this.palette,
    required this.waveProgress,
    required this.isStudying,
    required this.drift,
  });

  final StudyPalette palette;
  final double waveProgress;
  final bool isStudying;
  final double drift;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color.lerp(palette.top, Colors.black, 0.08)!,
        palette.middle,
        Color.lerp(palette.bottom, Colors.white, 0.12)!,
      ],
    );
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));

    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.45, -0.72),
        radius: 1.08,
        colors: [
          Colors.white.withValues(alpha: 0.28),
          palette.accent.withValues(alpha: 0.12),
          Colors.transparent,
        ],
      ).createShader(rect);
    canvas.drawRect(rect, glowPaint);

    _drawWaterSkin(canvas, size);
    _drawSoftRipples(canvas, size);

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.sqrt(
      size.width * size.width + size.height * size.height,
    );
    for (var i = 0; i < 5; i += 1) {
      final phase = (waveProgress + i * 0.11).clamp(0.0, 1.0);
      final radius = maxRadius * phase;
      final wavePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 + i * 0.7
        ..shader = SweepGradient(
          colors: [
            Colors.white.withValues(alpha: (1 - phase) * 0.20),
            palette.accent.withValues(alpha: (1 - phase) * 0.34),
            const Color(0xfff0abfc).withValues(alpha: (1 - phase) * 0.22),
            const Color(0xff7dd3fc).withValues(alpha: (1 - phase) * 0.30),
            Colors.white.withValues(alpha: (1 - phase) * 0.20),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius + 1));
      canvas.drawCircle(center, radius, wavePaint);
    }

    for (var i = 0; i < 24; i += 1) {
      final seed = i * 41.0;
      final x =
          (math.sin(drift * math.pi * 2 + seed) * 0.48 + 0.5) * size.width;
      final y =
          size.height * (0.06 + (i + 0.5) / 25 * 0.88) +
          math.cos(drift * math.pi * 2 + seed * 0.31) * 34;
      final radius = 5.0 + (i % 6) * 3.2;
      _drawFloatingBubble(
        canvas,
        Offset(x, y),
        radius,
        palette.accent.withValues(alpha: 0.10 + (i % 4) * 0.025),
      );
    }
  }

  void _drawWaterSkin(Canvas canvas, Size size) {
    for (var band = 0; band < 9; band += 1) {
      final y = size.height * (0.12 + band * 0.105);
      final amplitude = 10.0 + band * 1.4;
      final path = Path()..moveTo(0, y);
      for (var x = 0.0; x <= size.width + 24; x += 24) {
        final wave =
            math.sin(
              (x / size.width) * math.pi * 2.4 + drift * math.pi * 2 + band,
            ) *
            amplitude;
        path.lineTo(x, y + wave);
      }
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = band.isEven ? 1.5 : 1.0
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.055 + band * 0.006);
      canvas.drawPath(path, paint);
    }
  }

  void _drawSoftRipples(Canvas canvas, Size size) {
    final origins = [
      Offset(size.width * 0.22, size.height * 0.28),
      Offset(size.width * 0.76, size.height * 0.36),
      Offset(size.width * 0.34, size.height * 0.72),
    ];
    for (var originIndex = 0; originIndex < origins.length; originIndex += 1) {
      for (var ring = 0; ring < 4; ring += 1) {
        final phase = (drift + ring * 0.22 + originIndex * 0.13) % 1.0;
        final radius = 36 + phase * 150 + ring * 16;
        final alpha = (1 - phase) * 0.12;
        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..shader =
              SweepGradient(
                colors: [
                  palette.accent.withValues(alpha: alpha),
                  const Color(0xfff9a8d4).withValues(alpha: alpha * 0.9),
                  const Color(0xffa7f3d0).withValues(alpha: alpha),
                  Colors.white.withValues(alpha: alpha * 0.7),
                  palette.accent.withValues(alpha: alpha),
                ],
              ).createShader(
                Rect.fromCircle(center: origins[originIndex], radius: radius),
              );
        canvas.drawOval(
          Rect.fromCenter(
            center: origins[originIndex],
            width: radius * 1.8,
            height: radius * 0.62,
          ),
          paint,
        );
      }
    }
  }

  void _drawFloatingBubble(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
  ) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    final fill = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.45, -0.55),
        colors: [
          Colors.white.withValues(alpha: 0.22),
          color,
          Colors.transparent,
        ],
      ).createShader(rect);
    canvas.drawCircle(center, radius, fill);
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.22);
    canvas.drawCircle(center, radius, rim);
    canvas.drawCircle(
      center + Offset(-radius * 0.28, -radius * 0.28),
      radius * 0.18,
      Paint()..color = Colors.white.withValues(alpha: 0.24),
    );
  }

  @override
  bool shouldRepaint(OceanBackdropPainter oldDelegate) => true;
}

class BubblePainter extends CustomPainter {
  BubblePainter({
    required this.progress,
    required this.hold,
    required this.phase,
    required this.compression,
  });

  final double progress;
  final double hold;
  final double phase;
  final double compression;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = size.shortestSide / 2;
    final bubblePath = _wobblyBubblePath(center, radius * 0.95);
    final body = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.45),
        radius: 0.95,
        colors: _bubbleColorsForProgress(progress),
      ).createShader(rect);

    canvas.drawPath(bubblePath, body);

    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..shader = SweepGradient(
        colors: [
          Colors.white.withValues(alpha: 0.1),
          Colors.white.withValues(alpha: 0.82),
          Colors.white.withValues(alpha: 0.18),
          Colors.white.withValues(alpha: 0.48),
          Colors.white.withValues(alpha: 0.1),
        ],
      ).createShader(rect);
    canvas.drawPath(bubblePath, rim);

    final shine = Paint()
      ..shader =
          RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.72 - compression * 0.22),
              Colors.white.withValues(alpha: 0.0),
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(
                size.width * (0.33 + compression * 0.08),
                size.height * 0.28,
              ),
              radius: radius * 0.45,
            ),
          );
    canvas.drawCircle(
      Offset(size.width * 0.34, size.height * 0.29),
      radius * 0.36,
      shine,
    );

    final glint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.32 - compression * 0.10);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.72),
      math.pi * 1.13,
      math.pi * 0.42,
      false,
      glint,
    );

    if (hold > 0) {
      final holdPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.88);
      canvas.drawArc(
        rect.deflate(12),
        -math.pi / 2,
        math.pi * 2 * hold,
        false,
        holdPaint,
      );
    }

    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.14)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, size.height + 18),
        width: size.width * 0.56,
        height: 26,
      ),
      shadow,
    );
  }

  Path _wobblyBubblePath(Offset center, double radius) {
    final path = Path();
    const points = 144;
    final time = phase * math.pi * 2;
    for (var i = 0; i <= points; i += 1) {
      final angle = (i / points) * math.pi * 2;
      final wobble =
          math.sin(angle * 2.0 + time) * 0.026 +
          math.sin(angle * 3.0 - time * 2.0 + math.pi * 0.35) * 0.017 +
          math.sin(angle * 5.0 + time * 3.0 + math.pi * 0.7) * 0.009;
      final r = radius * (1 + wobble);
      final point = Offset(
        center.dx + math.cos(angle) * r,
        center.dy + math.sin(angle) * r,
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  @override
  bool shouldRepaint(BubblePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.hold != hold ||
        oldDelegate.phase != phase ||
        oldDelegate.compression != compression;
  }
}

String _smallDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  final hours = duration.inHours;
  return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
}
