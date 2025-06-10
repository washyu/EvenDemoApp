import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:demo_ai_even/services/ai_service_manager.dart';
import 'widgets/custom_agent_config.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final aiManager = Get.put(AIServiceManager());
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AI Provider',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Ollama Option
                  Obx(() => RadioListTile<AIProvider>(
                    title: const Text('Ollama (Local)'),
                    subtitle: Text(
                      aiManager.isOllamaAvailable.value
                        ? 'Connected - ${aiManager.selectedOllamaModel.value}'
                        : 'Not connected - Start with "ollama serve"',
                      style: TextStyle(
                        color: aiManager.isOllamaAvailable.value
                          ? Colors.green
                          : Colors.red,
                      ),
                    ),
                    value: AIProvider.ollama,
                    groupValue: aiManager.currentProvider.value,
                    onChanged: aiManager.isOllamaAvailable.value
                      ? (value) => aiManager.switchProvider(value!)
                      : null,
                  )),
                  
                  // Ollama Model Selection
                  Obx(() {
                    if (aiManager.isOllamaAvailable.value && 
                        aiManager.currentProvider.value == AIProvider.ollama &&
                        aiManager.ollamaModels.isNotEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 72, right: 16, bottom: 8),
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: aiManager.selectedOllamaModel.value,
                          items: aiManager.ollamaModels.map((model) {
                            return DropdownMenuItem(
                              value: model,
                              child: Text(model),
                            );
                          }).toList(),
                          onChanged: (model) {
                            if (model != null) {
                              aiManager.selectOllamaModel(model);
                            }
                          },
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                  
                  // DeepSeek Option
                  Obx(() => RadioListTile<AIProvider>(
                    title: const Text('DeepSeek'),
                    subtitle: const Text('Cloud API - Fast responses'),
                    value: AIProvider.deepseek,
                    groupValue: aiManager.currentProvider.value,
                    onChanged: (value) => aiManager.switchProvider(value!),
                  )),
                  
                  // Qwen Option
                  Obx(() => RadioListTile<AIProvider>(
                    title: const Text('Qwen'),
                    subtitle: const Text('Alibaba Cloud API'),
                    value: AIProvider.qwen,
                    groupValue: aiManager.currentProvider.value,
                    onChanged: (value) => aiManager.switchProvider(value!),
                  )),
                  
                  // Custom Agent Option
                  Obx(() => RadioListTile<AIProvider>(
                    title: const Text('Custom AI Agent'),
                    subtitle: Text(
                      aiManager.customAgentUrl.value.isEmpty
                        ? 'Configure your own agent'
                        : aiManager.customAgentUrl.value,
                      style: TextStyle(
                        color: aiManager.customAgentUrl.value.isNotEmpty
                          ? Colors.green
                          : Colors.grey,
                      ),
                    ),
                    value: AIProvider.customAgent,
                    groupValue: aiManager.currentProvider.value,
                    onChanged: (value) => aiManager.switchProvider(value!),
                  )),
                  
                  const SizedBox(height: 16),
                  
                  // Refresh Ollama Connection
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await aiManager.checkOllamaConnection();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              aiManager.isOllamaAvailable.value
                                ? 'Ollama connected!'
                                : 'Ollama not found. Make sure it\'s running.',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Check Ollama Connection'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Custom Agent Configuration
          Obx(() {
            if (aiManager.currentProvider.value == AIProvider.customAgent) {
              return CustomAgentConfig(
                onSave: (url, apiKey) {
                  aiManager.configureCustomAgent(url, apiKey);
                },
              );
            }
            return const SizedBox.shrink();
          }),
          
          const SizedBox(height: 16),
          
          // Memory Usage Tips
          Card(
            color: Colors.blue[50],
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💡 Memory Tips for Ollama',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text('• Close other apps when using 8B models'),
                  Text('• Consider 3B or 1B models for low memory'),
                  Text('• Responses are kept short for glasses display'),
                  Text('• Context window limited to 2048 tokens'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}