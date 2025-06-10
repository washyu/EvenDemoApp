import 'dart:typed_data';
import 'package:flutter/material.dart';

class PomodoroProto {
  // Custom protocol commands for Pomodoro features
  static const int CMD_POMODORO_STATUS = 0x70; // Show timer status
  static const int CMD_POMODORO_CONTROL = 0x71; // Control commands
  
  // Control sub-commands
  static const int CTRL_START_WORK = 0x01;
  static const int CTRL_START_BREAK = 0x02;
  static const int CTRL_PAUSE_RESUME = 0x03;
  static const int CTRL_STOP = 0x04;
  
  // Generate display data for glasses
  static String formatDisplayText({
    required String mainText,
    String? subText,
    String? statusLine,
  }) {
    final lines = <String>[];
    
    // Add empty line for centering
    lines.add('');
    
    // Main text (timer)
    lines.add(mainText);
    
    // Sub text (task name)
    if (subText != null && subText.isNotEmpty) {
      lines.add(subText);
    }
    
    // Status line
    if (statusLine != null && statusLine.isNotEmpty) {
      lines.add('');
      lines.add(statusLine);
    }
    
    return lines.join('\n');
  }

  // Format time for glasses display
  static String formatTimeDisplay(int seconds, {String? emoji}) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    final timeStr = '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    
    if (emoji != null) {
      return '$emoji $timeStr';
    }
    return timeStr;
  }

  // Create navigation hints for display
  static String getNavigationHint(bool isPaused) {
    if (isPaused) {
      return '← Stats  Resume →';
    }
    return '← Time  Task →';
  }

  // Generate full screen content
  static String generatePomodoroScreen({
    required int remainingSeconds,
    required String taskName,
    required bool isPaused,
    required bool isWork,
  }) {
    final emoji = isWork ? '🍅' : '☕';
    final mainText = formatTimeDisplay(remainingSeconds, emoji: emoji);
    final status = isPaused ? 'PAUSED' : '';
    final nav = getNavigationHint(isPaused);
    
    return formatDisplayText(
      mainText: mainText,
      subText: taskName,
      statusLine: status.isNotEmpty ? status : nav,
    );
  }

  // Parse touch events for Pomodoro mode
  static String? handlePomodoroTouch(int notifyIndex, String lr) {
    switch (notifyIndex) {
      case 1: // Single tap
        if (lr == 'L') {
          return 'show_stats';
        } else {
          return 'show_task';
        }
      case 0: // Double tap - specific to Pomodoro
        return 'pause_resume';
      case 23: // Long press
        return 'voice_command';
      default:
        return null;
    }
  }

  // Generate stats display
  static String generateStatsScreen({
    required int completedToday,
    required int totalMinutes,
    required int currentStreak,
  }) {
    return formatDisplayText(
      mainText: '📊 Today\'s Stats',
      subText: '$completedToday pomodoros\n$totalMinutes min focused',
      statusLine: '🔥 $currentStreak day streak',
    );
  }

  // Generate task list display
  static String generateTaskScreen({
    required String currentTask,
    required List<String> upcomingTasks,
  }) {
    final upcoming = upcomingTasks.take(2).join('\n');
    return formatDisplayText(
      mainText: '📋 Current Task',
      subText: currentTask,
      statusLine: upcomingTasks.isNotEmpty ? 'Next: ${upcomingTasks.first}' : '',
    );
  }
}