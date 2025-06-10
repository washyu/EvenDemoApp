import 'package:flutter/material.dart';
import 'package:even_pomodoro/even_pomodoro.dart';
import 'package:demo_ai_even/services/proto.dart';
import 'package:demo_ai_even/services/evenai.dart';

// Integration wrapper for Pomodoro feature
class PomodoroIntegration {
  static void integrateWithGlasses(BuildContext context) {
    // Initialize Pomodoro service with glasses communication
    PomodoroService.instance.init(
      sendToGlasses: (text, status) async {
        // Use existing Proto service to send to glasses
        await Proto.sendEvenAIData(
          text,
          newScreen: status,
          pos: 0,
          current_page_num: 1,
          max_page_num: 1,
        );
      },
      voiceResponse: (response) {
        // Update display with voice command response
        EvenAI.updateDynamicText(response);
      },
    );
  }
  
  // Modified BLE handler for Pomodoro mode
  static bool handlePomodoroTouch(int notifyIndex, String lr) {
    if (!PomodoroService.instance.isActive) {
      return false; // Not in Pomodoro mode
    }
    
    // Handle touches in Pomodoro mode
    PomodoroService.instance.handleTouch(notifyIndex, lr);
    return true; // Touch was handled
  }
  
  // Voice command integration
  static bool handlePomodoroVoice(String transcript) {
    final lowercaseTranscript = transcript.toLowerCase();
    
    // Check if this is a Pomodoro command
    final pomodoroKeywords = [
      'pomodoro', 'timer', 'focus', 'break', 
      'pause', 'resume', 'time left', 'stats'
    ];
    
    bool isPomodoroCommand = pomodoroKeywords.any(
      (keyword) => lowercaseTranscript.contains(keyword)
    );
    
    if (isPomodoroCommand) {
      PomodoroService.instance.processVoiceCommand(transcript);
      return true;
    }
    
    return false;
  }
  
  // Navigation to Pomodoro page
  static void navigateToPomodoroPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PomodoroPage(
          onSendToGlasses: (text, status) async {
            await Proto.sendEvenAIData(
              text,
              newScreen: status,
              pos: 0,
              current_page_num: 1,
              max_page_num: 1,
            );
          },
        ),
      ),
    );
  }
}