import 'dart:async';
import 'package:get/get.dart';
import 'pomodoro_controller.dart';
import 'pomodoro_proto.dart';
import 'pomodoro_silent_controls.dart';

class PomodoroService {
  static PomodoroService? _instance;
  static PomodoroService get instance => _instance ??= PomodoroService._();
  
  final controller = Get.put(PomodoroController());
  final silentControls = PomodoroSilentControls();
  Timer? _displayUpdateTimer;
  
  // Track recent gestures for pattern detection
  final List<String> recentGestures = [];
  Timer? gestureResetTimer;
  
  // Callback for sending data to glasses
  Function(String text, int status)? onSendToGlasses;
  
  // Callback for voice command results
  Function(String response)? onVoiceResponse;
  
  PomodoroService._();
  
  void init({
    required Function(String text, int status) sendToGlasses,
    Function(String response)? voiceResponse,
  }) {
    onSendToGlasses = sendToGlasses;
    onVoiceResponse = voiceResponse;
    
    // Start display update timer
    _startDisplayUpdates();
  }
  
  void _startDisplayUpdates() {
    _displayUpdateTimer?.cancel();
    _displayUpdateTimer = Timer.periodic(Duration(seconds: 1), (_) {
      if (controller.currentSession.value != null && onSendToGlasses != null) {
        final session = controller.currentSession.value!;
        final displayText = PomodoroProto.generatePomodoroScreen(
          remainingSeconds: session.remainingSeconds,
          taskName: session.taskName ?? '',
          isPaused: session.isPaused,
          isWork: session.type == PomodoroType.work,
        );
        
        // Send to glasses with appropriate status
        onSendToGlasses!(displayText, 0x50); // Manual mode
      }
    });
  }
  
  // Handle touch events from glasses (silent mode)
  void handleTouch(int notifyIndex, String lr) {
    // Build gesture string
    String gesture = '';
    if (notifyIndex == 1) {
      gesture = (lr == 'L') ? 'left' : 'right';
    } else if (notifyIndex == 0) {
      gesture = 'double';
    } else if (notifyIndex == 23) {
      // Long press opens menu instead of voice
      _showPomodoroMenu();
      return;
    }
    
    // Track gesture for pattern detection
    _trackGesture(gesture);
    
    // If timer not active, show menu
    if (controller.currentSession.value == null && gesture != '') {
      _showPomodoroMenu();
      return;
    }
    
    // Handle gesture in current context
    final action = silentControls.handleGesture(
      gesture, 
      controller.currentSession.value != null,
      controller.currentSession.value?.isPaused ?? false
    );
    
    _executeAction(action);
  }
  
  void _trackGesture(String gesture) {
    if (gesture.isEmpty) return;
    
    recentGestures.add(gesture);
    if (recentGestures.length > 3) {
      recentGestures.removeAt(0);
    }
    
    // Reset gesture tracking after 2 seconds
    gestureResetTimer?.cancel();
    gestureResetTimer = Timer(Duration(seconds: 2), () {
      recentGestures.clear();
    });
    
    // Check for special patterns
    final pattern = PomodoroSilentControls.detectGesturePattern(recentGestures);
    if (pattern != null) {
      _executePattern(pattern);
      recentGestures.clear();
    }
  }
  
  void _executeAction(String action) {
    switch (action) {
      case 'show_quick_start':
      case 'show_custom_timer':
      case 'back_to_main':
        onSendToGlasses?.call(silentControls.getMenuDisplay(), 0x50);
        break;
      case 'start_work_25':
        controller.startWork();
        _sendStatusUpdate();
        break;
      case 'start_break_5':
        controller.startBreak(false);
        _sendStatusUpdate();
        break;
      case 'pause':
      case 'resume':
        controller.pauseResume();
        _sendStatusUpdate();
        break;
      case 'stop':
        controller.stopSession();
        _showPomodoroMenu();
        break;
      case 'show_stats':
        _showStats();
        break;
      case 'show_tasks':
        _showCurrentTask();
        break;
      case 'exit_menu':
        silentControls.currentMenu = 'active_timer';
        _sendStatusUpdate();
        break;
      default:
        if (action.startsWith('start_custom_')) {
          final minutes = int.tryParse(action.split('_').last) ?? 25;
          controller.startWork(taskName: '$minutes min Focus');
          _sendStatusUpdate();
        } else if (action.startsWith('update_custom_')) {
          final minutes = action.split('_').last;
          final menu = silentControls.menuStructure['custom_timer']!
            .replaceAll('15 min', '$minutes min');
          onSendToGlasses?.call(menu, 0x50);
        }
    }
  }
  
  void _executePattern(String pattern) {
    switch (pattern) {
      case 'quick_start_work':
        controller.startWork(taskName: 'Quick Focus');
        _sendStatusUpdate();
        break;
      case 'quick_break':
        controller.startBreak(false);
        _sendStatusUpdate();
        break;
      case 'emergency_stop':
        controller.stopSession();
        onSendToGlasses?.call('🛑 Timer Stopped', 0x50);
        break;
    }
  }
  
  void _showPomodoroMenu() {
    silentControls.currentMenu = 'main';
    onSendToGlasses?.call(silentControls.getMenuDisplay(), 0x50);
  }
  
  void _showStats() {
    final stats = PomodoroProto.generateStatsScreen(
      completedToday: controller.todaySessions.where((s) => s.isCompleted).length,
      totalMinutes: controller.todaySessions
          .where((s) => s.isCompleted && s.type == PomodoroType.work)
          .fold(0, (sum, s) => sum + (s.duration ~/ 60)),
      currentStreak: _calculateStreak(),
    );
    
    onSendToGlasses?.call(stats, 0x50);
    
    // Return to timer after 3 seconds
    Timer(Duration(seconds: 3), () => _sendStatusUpdate());
  }
  
  void _showCurrentTask() {
    final task = PomodoroProto.generateTaskScreen(
      currentTask: controller.currentSession.value?.taskName ?? 'No task',
      upcomingTasks: [], // Could be extended with task queue
    );
    
    onSendToGlasses?.call(task, 0x50);
    
    // Return to timer after 3 seconds
    Timer(Duration(seconds: 3), () => _sendStatusUpdate());
  }
  
  void _sendStatusUpdate() {
    if (controller.currentSession.value == null) {
      onSendToGlasses?.call('🍅 Ready to focus?\n\nLong press to start', 0x50);
      return;
    }
    
    final session = controller.currentSession.value!;
    final displayText = PomodoroProto.generatePomodoroScreen(
      remainingSeconds: session.remainingSeconds,
      taskName: session.taskName ?? '',
      isPaused: session.isPaused,
      isWork: session.type == PomodoroType.work,
    );
    
    onSendToGlasses?.call(displayText, 0x50);
  }
  
  // Process voice commands
  void processVoiceCommand(String command) {
    controller.processVoiceCommand(command);
    
    // Get appropriate response
    String response;
    if (command.toLowerCase().contains('start')) {
      response = "Started ${controller.currentSession.value?.taskName ?? 'pomodoro'}";
    } else if (command.toLowerCase().contains('time')) {
      response = controller.announceTime();
    } else if (command.toLowerCase().contains('stats')) {
      response = controller.showStats();
    } else if (command.toLowerCase().contains('task')) {
      response = controller.announceCurrentTask();
    } else {
      response = "Command processed";
    }
    
    onVoiceResponse?.call(response);
  }
  
  // Start a new pomodoro with task name
  void startPomodoro({String? taskName}) {
    controller.startWork(taskName: taskName);
    _sendStatusUpdate();
  }
  
  // Check if service is active
  bool get isActive => controller.currentSession.value != null;
  
  int _calculateStreak() {
    // Simple streak calculation - could be enhanced with persistence
    return controller.todaySessions.where((s) => s.isCompleted).isNotEmpty ? 1 : 0;
  }
  
  void dispose() {
    _displayUpdateTimer?.cancel();
    controller.dispose();
  }
}