class PomodoroSession {
  final DateTime startTime;
  final int duration; // in seconds
  final String? taskName;
  final PomodoroType type;
  DateTime? endTime;
  bool isCompleted;
  bool isPaused;
  int remainingSeconds;

  PomodoroSession({
    required this.startTime,
    required this.duration,
    this.taskName,
    required this.type,
    this.endTime,
    this.isCompleted = false,
    this.isPaused = false,
  }) : remainingSeconds = duration;

  String get formattedTime {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get displayText {
    final emoji = type == PomodoroType.work ? '🍅' : '☕';
    final status = isPaused ? ' (Paused)' : '';
    return '$emoji ${formattedTime}$status';
  }
}

enum PomodoroType { work, shortBreak, longBreak }