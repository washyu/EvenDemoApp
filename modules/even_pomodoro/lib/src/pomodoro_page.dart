import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'pomodoro_controller.dart';
import 'pomodoro_service.dart';

class PomodoroPage extends StatefulWidget {
  final Function(String text, int status) onSendToGlasses;
  
  const PomodoroPage({
    Key? key,
    required this.onSendToGlasses,
  }) : super(key: key);

  @override
  State<PomodoroPage> createState() => _PomodoroPageState();
}

class _PomodoroPageState extends State<PomodoroPage> {
  final controller = Get.find<PomodoroController>();
  final taskController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    // Initialize service with glasses communication
    PomodoroService.instance.init(
      sendToGlasses: widget.onSendToGlasses,
      voiceResponse: (response) {
        // Handle voice responses
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response)),
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pomodoro Timer'),
        backgroundColor: Colors.red[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Timer Display
            Obx(() {
              final session = controller.currentSession.value;
              return Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: session?.type == PomodoroType.work 
                    ? Colors.red[50] 
                    : Colors.green[50],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text(
                      session?.formattedTime ?? '25:00',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      session?.taskName ?? 'Ready to focus?',
                      style: const TextStyle(fontSize: 18),
                    ),
                    if (session?.isPaused ?? false)
                      const Text(
                        'PAUSED',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              );
            }),
            
            const SizedBox(height: 32),
            
            // Task Input
            TextField(
              controller: taskController,
              decoration: InputDecoration(
                labelText: 'What are you working on?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.task),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Control Buttons
            Obx(() {
              final isActive = controller.currentSession.value != null;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (!isActive)
                    ElevatedButton.icon(
                      onPressed: () {
                        PomodoroService.instance.startPomodoro(
                          taskName: taskController.text.isNotEmpty 
                            ? taskController.text 
                            : null,
                        );
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  
                  if (isActive) ...[
                    ElevatedButton.icon(
                      onPressed: () => controller.pauseResume(),
                      icon: Icon(
                        controller.currentSession.value?.isPaused ?? false
                          ? Icons.play_arrow
                          : Icons.pause,
                      ),
                      label: Text(
                        controller.currentSession.value?.isPaused ?? false
                          ? 'Resume'
                          : 'Pause',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[700],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => controller.stopSession(),
                      icon: const Icon(Icons.stop),
                      label: const Text('Stop'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[700],
                      ),
                    ),
                  ],
                ],
              );
            }),
            
            const SizedBox(height: 32),
            
            // Stats
            Obx(() => Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    '🍅 Today',
                    '${controller.todaySessions.where((s) => s.isCompleted).length}',
                  ),
                  _buildStatItem(
                    '⏱️ Focus Time',
                    '${controller.todaySessions
                      .where((s) => s.isCompleted && s.type == PomodoroType.work)
                      .fold(0, (sum, s) => sum + (s.duration ~/ 60))} min',
                  ),
                  _buildStatItem(
                    '🔥 Streak',
                    '${controller.todaySessions.isNotEmpty ? 1 : 0} day',
                  ),
                ],
              ),
            )),
            
            const Spacer(),
            
            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Glasses Controls:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('• Left tap: Show stats'),
                  Text('• Right tap: Show current task'),
                  Text('• Double tap: Pause/Resume'),
                  Text('• Long press: Voice command'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  @override
  void dispose() {
    taskController.dispose();
    super.dispose();
  }
}