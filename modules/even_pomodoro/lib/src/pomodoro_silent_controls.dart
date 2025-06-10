import 'dart:async';

class PomodoroSilentControls {
  // Gesture-based menu system
  static const Map<String, String> menuStructure = {
    'main': '''
🍅 Pomodoro Menu

← Quick Start
→ Custom Timer
↕ Exit Menu
    ''',
    
    'quick_start': '''
⏱️ Quick Start

← 25 min Work
→ 5 min Break
↕ Back
    ''',
    
    'custom_timer': '''
⏱️ Set Duration

← -5 minutes
→ +5 minutes
↕ Start (15 min)
    ''',
    
    'active_timer': '''
🍅 23:45

← Stats
→ Tasks
↕ Pause
    ''',
    
    'paused': '''
⏸️ PAUSED

← Resume
→ Stop
↕ Back to Timer
    ''',
    
    'stats': '''
📊 Today: 4 🍅

Focus: 100 min
Breaks: 20 min
↕ Back
    ''',
  };
  
  String currentMenu = 'main';
  int customMinutes = 15;
  Timer? navigationTimer;
  
  // Handle navigation without voice
  String handleGesture(String gesture, bool isTimerActive, bool isPaused) {
    // Cancel auto-return timer
    navigationTimer?.cancel();
    
    // Context-aware navigation
    if (isTimerActive && currentMenu == 'active_timer') {
      return _handleActiveTimerGesture(gesture, isPaused);
    }
    
    switch (currentMenu) {
      case 'main':
        return _handleMainMenu(gesture);
      case 'quick_start':
        return _handleQuickStart(gesture);
      case 'custom_timer':
        return _handleCustomTimer(gesture);
      case 'stats':
        return _handleStats(gesture);
      default:
        return 'back_to_timer';
    }
  }
  
  String _handleMainMenu(String gesture) {
    switch (gesture) {
      case 'left':
        currentMenu = 'quick_start';
        return 'show_quick_start';
      case 'right':
        currentMenu = 'custom_timer';
        return 'show_custom_timer';
      case 'double':
        return 'exit_menu';
      default:
        return 'stay';
    }
  }
  
  String _handleQuickStart(String gesture) {
    switch (gesture) {
      case 'left':
        currentMenu = 'active_timer';
        return 'start_work_25';
      case 'right':
        currentMenu = 'active_timer';
        return 'start_break_5';
      case 'double':
        currentMenu = 'main';
        return 'back_to_main';
      default:
        return 'stay';
    }
  }
  
  String _handleCustomTimer(String gesture) {
    switch (gesture) {
      case 'left':
        customMinutes = (customMinutes - 5).clamp(5, 60);
        return 'update_custom_$customMinutes';
      case 'right':
        customMinutes = (customMinutes + 5).clamp(5, 60);
        return 'update_custom_$customMinutes';
      case 'double':
        currentMenu = 'active_timer';
        return 'start_custom_$customMinutes';
      default:
        return 'stay';
    }
  }
  
  String _handleActiveTimerGesture(String gesture, bool isPaused) {
    if (isPaused) {
      switch (gesture) {
        case 'left':
          return 'resume';
        case 'right':
          return 'stop';
        case 'double':
          return 'back_to_timer';
        default:
          return 'stay';
      }
    }
    
    switch (gesture) {
      case 'left':
        currentMenu = 'stats';
        _startAutoReturn();
        return 'show_stats';
      case 'right':
        _startAutoReturn();
        return 'show_tasks';
      case 'double':
        return 'pause';
      default:
        return 'stay';
    }
  }
  
  String _handleStats(String gesture) {
    if (gesture == 'double') {
      currentMenu = 'active_timer';
      return 'back_to_timer';
    }
    return 'stay';
  }
  
  void _startAutoReturn() {
    navigationTimer?.cancel();
    navigationTimer = Timer(Duration(seconds: 5), () {
      currentMenu = 'active_timer';
    });
  }
  
  String getMenuDisplay() {
    return menuStructure[currentMenu] ?? menuStructure['main']!;
  }
  
  // Quick gesture patterns for common actions
  static String? detectGesturePattern(List<String> recentGestures) {
    if (recentGestures.length < 2) return null;
    
    final pattern = recentGestures.join('-');
    
    // Quick patterns
    switch (pattern) {
      case 'left-right-left':
        return 'quick_start_work';
      case 'right-left-right':
        return 'quick_break';
      case 'double-double':
        return 'emergency_stop';
      default:
        return null;
    }
  }
}

// Enhanced display for silent mode
class SilentModeDisplay {
  static String formatTimerScreen({
    required int seconds,
    required bool isPaused,
    required String mode,
  }) {
    final emoji = mode == 'work' ? '🍅' : '☕';
    final time = _formatTime(seconds);
    final status = isPaused ? '⏸️ PAUSED' : '';
    
    // Visual indicators for gesture hints
    final hints = isPaused 
      ? '← Resume  Stop →'
      : '← Stats  Tasks →';
    
    return '''
$emoji $time
$status

$hints
↕ ${isPaused ? 'Timer' : 'Pause'}
    ''';
  }
  
  static String formatQuickMenu() {
    return '''
Quick Actions:

👆 = Next
👆👆 = Select
← → = Navigate

Ready?
    ''';
  }
  
  static String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}