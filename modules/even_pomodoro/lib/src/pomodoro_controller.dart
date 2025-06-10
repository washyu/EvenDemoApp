import 'dart:async';
import 'package:get/get.dart';
import 'models/pomodoro_session.dart';

class PomodoroController extends GetxController {
  static const int workDuration = 25 * 60; // 25 minutes
  static const int shortBreakDuration = 5 * 60; // 5 minutes
  static const int longBreakDuration = 15 * 60; // 15 minutes
  
  final Rx<PomodoroSession?> currentSession = Rx<PomodoroSession?>(null);
  final RxInt pomodoroCount = 0.obs;
  final RxList<PomodoroSession> todaySessions = <PomodoroSession>[].obs;
  
  Timer? _timer;
  
  // Voice command handlers
  final Map<String, Function> voiceCommands = {
    'start pomodoro': () => startWork(),
    'start timer': () => startWork(),
    'start 25 minute timer': () => startWork(),
    'pause': () => pauseResume(),
    'resume': () => pauseResume(),
    'stop': () => stopSession(),
    'how much time': () => announceTime(),
    'time left': () => announceTime(),
    'take a break': () => startBreak(false),
    'skip break': () => skipBreak(),
    'show stats': () => showStats(),
    'current task': () => announceCurrentTask(),
  };

  void startWork({String? taskName}) {
    stopSession();
    currentSession.value = PomodoroSession(
      startTime: DateTime.now(),
      duration: workDuration,
      taskName: taskName ?? 'Focus Session ${pomodoroCount.value + 1}',
      type: PomodoroType.work,
    );
    _startTimer();
  }

  void startBreak(bool isLong) {
    stopSession();
    currentSession.value = PomodoroSession(
      startTime: DateTime.now(),
      duration: isLong ? longBreakDuration : shortBreakDuration,
      taskName: isLong ? 'Long Break' : 'Short Break',
      type: isLong ? PomodoroType.longBreak : PomodoroType.shortBreak,
    );
    _startTimer();
  }

  void pauseResume() {
    if (currentSession.value == null) return;
    
    currentSession.value!.isPaused = !currentSession.value!.isPaused;
    currentSession.refresh();
    
    if (currentSession.value!.isPaused) {
      _timer?.cancel();
    } else {
      _startTimer();
    }
  }

  void stopSession() {
    _timer?.cancel();
    if (currentSession.value != null) {
      currentSession.value!.endTime = DateTime.now();
      if (currentSession.value!.type == PomodoroType.work && 
          currentSession.value!.remainingSeconds < 60) {
        currentSession.value!.isCompleted = true;
        pomodoroCount.value++;
        todaySessions.add(currentSession.value!);
      }
    }
    currentSession.value = null;
  }

  void skipBreak() {
    if (currentSession.value?.type != PomodoroType.work) {
      stopSession();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (currentSession.value == null || currentSession.value!.isPaused) return;
      
      currentSession.value!.remainingSeconds--;
      currentSession.refresh();
      
      if (currentSession.value!.remainingSeconds <= 0) {
        _onTimerComplete();
      }
    });
  }

  void _onTimerComplete() {
    stopSession();
    // Trigger break or work based on what just finished
    if (currentSession.value?.type == PomodoroType.work) {
      // Suggest break after work
      final isLongBreak = pomodoroCount.value % 4 == 0;
      // This would trigger a notification to glasses
    }
  }

  String announceTime() {
    if (currentSession.value == null) {
      return "No active timer";
    }
    return currentSession.value!.displayText;
  }

  String announceCurrentTask() {
    if (currentSession.value == null) {
      return "No active session";
    }
    return currentSession.value!.taskName ?? "Unnamed task";
  }

  String showStats() {
    final completed = todaySessions.where((s) => s.isCompleted).length;
    final totalMinutes = todaySessions
        .where((s) => s.isCompleted && s.type == PomodoroType.work)
        .fold(0, (sum, s) => sum + (s.duration ~/ 60));
    
    return "Today: $completed pomodoros, $totalMinutes minutes focused";
  }

  // Handle voice commands from glasses
  void processVoiceCommand(String command) {
    final lowercaseCommand = command.toLowerCase();
    for (final entry in voiceCommands.entries) {
      if (lowercaseCommand.contains(entry.key)) {
        entry.value();
        return;
      }
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}