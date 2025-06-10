import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomAgentConfig extends StatefulWidget {
  final Function(String url, String? apiKey) onSave;
  
  const CustomAgentConfig({
    Key? key,
    required this.onSave,
  }) : super(key: key);

  @override
  State<CustomAgentConfig> createState() => _CustomAgentConfigState();
}

class _CustomAgentConfigState extends State<CustomAgentConfig> {
  final urlController = TextEditingController();
  final apiKeyController = TextEditingController();
  String selectedPreset = 'custom';
  
  final presets = {
    'custom': 'Custom Agent',
    'ollama': 'Ollama (Local)',
    'openai-compatible': 'OpenAI Compatible',
    'langchain': 'LangChain Server',
    'autogen': 'AutoGen Agent',
  };
  
  @override
  void initState() {
    super.initState();
    // Load saved config
    urlController.text = 'http://localhost:8000';
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Custom AI Agent',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Connect to your own AI agent or RAG system',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            
            // Preset selector
            DropdownButtonFormField<String>(
              value: selectedPreset,
              decoration: const InputDecoration(
                labelText: 'Agent Type',
                border: OutlineInputBorder(),
              ),
              items: presets.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedPreset = value!;
                  // Set default URLs based on preset
                  switch (value) {
                    case 'ollama':
                      urlController.text = 'http://localhost:11434';
                      break;
                    case 'openai-compatible':
                      urlController.text = 'http://localhost:8000/v1';
                      break;
                    case 'langchain':
                      urlController.text = 'http://localhost:8000';
                      break;
                    case 'autogen':
                      urlController.text = 'http://localhost:8080';
                      break;
                  }
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // URL input
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'Agent URL',
                hintText: 'http://localhost:8000',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // API Key (optional)
            TextField(
              controller: apiKeyController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'API Key (optional)',
                hintText: 'Leave empty if not required',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.key),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Example formats
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your agent will receive:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '''
{
  "message": "User's question",
  "context": {
    "device": "Even G1 Glasses",
    "interface": "AR Display",
    "constraints": "Short responses preferred"
  }
}''',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Test connection button
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      // Test connection
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Testing connection...'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                      
                      // TODO: Implement actual test
                      await Future.delayed(const Duration(seconds: 1));
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Connection successful!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    icon: const Icon(Icons.wifi_tethering),
                    label: const Text('Test Connection'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      widget.onSave(
                        urlController.text,
                        apiKeyController.text.isEmpty ? null : apiKeyController.text,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Agent configured!'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('Save'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Tips
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    '💡 Tips',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('• Your agent should return concise responses'),
                  Text('• Include user context in your agent\'s prompts'),
                  Text('• Test with simple questions first'),
                  Text('• Ensure your agent is accessible from your phone\'s network'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    urlController.dispose();
    apiKeyController.dispose();
    super.dispose();
  }
}