# Even Pomodoro Plugin

A Pomodoro timer plugin for Even G1 glasses that provides ADHD-friendly focus management.

## Features

- 🍅 25-minute work sessions
- ☕ 5-minute short breaks
- 🌴 15-minute long breaks
- 📊 Daily statistics tracking
- 🎯 Task management
- 🔊 Voice control support
- 👆 Touch gesture controls

## Touch Controls

When Pomodoro is active on glasses:
- **Left tap**: Show daily stats
- **Right tap**: Show current task
- **Double tap**: Pause/Resume timer
- **Long press**: Activate voice command

## Voice Commands

- "Start pomodoro" / "Start timer"
- "How much time left?"
- "Pause" / "Resume"
- "Show my stats"
- "What's my current task?"
- "Take a break"
- "Skip break"

## Integration

### 1. Add to pubspec.yaml
```yaml
dependencies:
  even_pomodoro:
    path: modules/even_pomodoro/
```

### 2. Modify BLE handler in ble_manager.dart
```dart
// In _handleReceivedData method, add:
import 'package:demo_ai_even/views/features/pomodoro_integration.dart';

if (res.data[0].toInt() == 0xF5) {
  final notifyIndex = res.data[1].toInt();
  
  // Check if Pomodoro handles this touch
  if (PomodoroIntegration.handlePomodoroTouch(notifyIndex, res.lr)) {
    return;
  }
  
  // Otherwise, handle normally...
}
```

### 3. Add to voice processing in evenai.dart
```dart
// In recordOverByOS method, before sending to AI:
if (PomodoroIntegration.handlePomodoroVoice(combinedText)) {
  return; // Handled by Pomodoro
}
```

### 4. Add to features page
```dart
ListTile(
  leading: Icon(Icons.timer, color: Colors.red),
  title: Text('Pomodoro Timer'),
  subtitle: Text('Focus management with timer'),
  onTap: () => PomodoroIntegration.navigateToPomodoroPage(context),
),
```

## Architecture

The plugin follows a modular architecture:

- **PomodoroController**: Core timer logic and state management
- **PomodoroService**: Bridge between glasses and timer
- **PomodoroProto**: Display formatting and protocol handling
- **PomodoroPage**: Flutter UI for phone control
- **PomodoroSession**: Data model for timer sessions

## Customization

### Timer Durations
Edit in `pomodoro_controller.dart`:
```dart
static const int workDuration = 25 * 60; // 25 minutes
static const int shortBreakDuration = 5 * 60; // 5 minutes
```

### Display Format
Modify `pomodoro_proto.dart` to change how time appears on glasses.

### Voice Commands
Add new commands in `pomodoro_controller.dart` voiceCommands map.

## Future Enhancements

- Task queue management
- Calendar integration
- Distraction tracking
- Focus music control
- Team pomodoro sessions
- Cloud sync for stats