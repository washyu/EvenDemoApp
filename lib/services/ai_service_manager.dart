import 'package:get/get.dart';
import 'api_services.dart';
import 'api_services_deepseek.dart';
import 'api_services_ollama.dart';
import 'api_custom_agent.dart';

enum AIProvider {
  deepseek,
  qwen,
  ollama,
  customAgent,
}

class AIServiceManager extends GetxController {
  static AIServiceManager get instance => Get.find();
  
  final Rx<AIProvider> currentProvider = AIProvider.ollama.obs;
  final RxBool isOllamaAvailable = false.obs;
  final RxList<String> ollamaModels = <String>[].obs;
  final RxString selectedOllamaModel = 'deepseek-r1:8b'.obs;
  
  late ApiOllamaService _ollamaService;
  late ApiDeepSeekService _deepseekService;
  late ApiService _qwenService;
  ApiCustomAgentService? _customAgentService;
  
  // Custom agent configuration
  final RxString customAgentUrl = 'http://localhost:8000'.obs;
  final RxnString customAgentApiKey = RxnString();
  
  @override
  void onInit() {
    super.onInit();
    _initializeServices();
    checkOllamaConnection();
  }
  
  void _initializeServices() {
    _ollamaService = ApiOllamaService(model: selectedOllamaModel.value);
    _deepseekService = ApiDeepSeekService();
    _qwenService = ApiService();
  }
  
  Future<void> checkOllamaConnection() async {
    try {
      final models = await _ollamaService.getAvailableModels();
      isOllamaAvailable.value = models.isNotEmpty;
      ollamaModels.value = models;
      
      if (models.isNotEmpty && !models.contains(selectedOllamaModel.value)) {
        // Default to first available model if selected isn't available
        selectedOllamaModel.value = models.first;
        _ollamaService = ApiOllamaService(model: selectedOllamaModel.value);
      }
      
      print("Ollama available: ${isOllamaAvailable.value}");
      print("Available models: ${models.join(', ')}");
    } catch (e) {
      isOllamaAvailable.value = false;
      print("Ollama not available: $e");
    }
  }
  
  void switchProvider(AIProvider provider) {
    currentProvider.value = provider;
    print("Switched to AI provider: ${provider.name}");
  }
  
  void selectOllamaModel(String model) {
    selectedOllamaModel.value = model;
    _ollamaService = ApiOllamaService(model: model);
    print("Selected Ollama model: $model");
  }
  
  void configureCustomAgent(String url, String? apiKey) {
    customAgentUrl.value = url;
    customAgentApiKey.value = apiKey;
    _customAgentService = ApiCustomAgentService(
      baseUrl: url,
      apiKey: apiKey,
    );
    print("Configured custom agent at: $url");
  }
  
  Future<String> sendChatRequest(String question) async {
    // Add provider prefix for debugging
    String response;
    final startTime = DateTime.now();
    
    try {
      switch (currentProvider.value) {
        case AIProvider.ollama:
          if (!isOllamaAvailable.value) {
            await checkOllamaConnection();
            if (!isOllamaAvailable.value) {
              return "Ollama is not running. Please start it with 'ollama serve'";
            }
          }
          response = await _ollamaService.sendChatRequest(question);
          break;
        case AIProvider.deepseek:
          response = await _deepseekService.sendChatRequest(question);
          break;
        case AIProvider.qwen:
          response = await _qwenService.sendChatRequest(question);
          break;
        case AIProvider.customAgent:
          if (_customAgentService == null) {
            return "Please configure your custom agent first";
          }
          response = await _customAgentService!.sendChatRequest(question);
          break;
      }
      
      final duration = DateTime.now().difference(startTime);
      print("AI response time: ${duration.inMilliseconds}ms");
      
      return response;
    } catch (e) {
      print("AI request failed: $e");
      return "AI request failed. Please check your connection.";
    }
  }
  
  String get currentProviderName {
    switch (currentProvider.value) {
      case AIProvider.ollama:
        return "Ollama (${selectedOllamaModel.value})";
      case AIProvider.deepseek:
        return "DeepSeek";
      case AIProvider.qwen:
        return "Qwen";
    }
  }
}