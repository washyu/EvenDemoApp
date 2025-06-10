import 'package:dio/dio.dart';

class ApiOllamaService {
  late Dio _dio;
  final String model;
  final String baseUrl;
  
  // Memory-efficient settings for Ollama
  final int contextSize;
  final double temperature;

  ApiOllamaService({
    this.baseUrl = 'http://192.168.1.100:11434', // Replace with your Mac's IP
    this.model = 'deepseek-r1:8b',
    this.contextSize = 2048, // Reduced for memory efficiency
    this.temperature = 0.7,
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        headers: {
          'Content-Type': 'application/json',
        },
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60), // R1 can be slower
      ),
    );
  }

  Future<String> sendChatRequest(String question) async {
    // Ollama native API (more efficient than OpenAI compatibility)
    final data = {
      "model": model,
      "prompt": question,
      "stream": false,
      "options": {
        "num_ctx": contextSize,
        "temperature": temperature,
        "top_p": 0.9,
        "repeat_penalty": 1.1,
      },
      "system": "You are a helpful AI assistant on smart glasses. Keep responses concise and clear. Maximum 3-4 sentences.",
    };
    
    print("Ollama request to $baseUrl with model: $model");

    try {
      final response = await _dio.post('/api/generate', data: data);

      if (response.statusCode == 200) {
        final responseData = response.data;
        final content = responseData['response'] ?? "Unable to generate response";
        
        // Log token usage for memory monitoring
        final totalTokens = responseData['eval_count'] ?? 0;
        print("Ollama tokens used: $totalTokens");
        
        return content.trim();
      } else {
        print("Ollama request failed with status: ${response.statusCode}");
        return "Request failed with status: ${response.statusCode}";
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        return "Ollama connection timeout. Make sure Ollama is running (ollama serve)";
      } else if (e.response != null) {
        print("Ollama Error: ${e.response?.statusCode}, ${e.response?.data}");
        return "Ollama error: ${e.response?.data['error'] ?? 'Unknown error'}";
      } else {
        print("Ollama Error: ${e.message}");
        return "Failed to connect to Ollama. Is it running on $baseUrl?";
      }
    }
  }
  
  // Test connection to Ollama
  Future<bool> testConnection() async {
    try {
      final response = await _dio.get('/api/tags');
      if (response.statusCode == 200) {
        final models = response.data['models'] as List;
        print("Available Ollama models: ${models.map((m) => m['name']).join(', ')}");
        return models.any((m) => m['name'] == model);
      }
      return false;
    } catch (e) {
      print("Ollama connection test failed: $e");
      return false;
    }
  }
  
  // List available models
  Future<List<String>> getAvailableModels() async {
    try {
      final response = await _dio.get('/api/tags');
      if (response.statusCode == 200) {
        final models = response.data['models'] as List;
        return models.map<String>((m) => m['name'] as String).toList();
      }
      return [];
    } catch (e) {
      print("Failed to get Ollama models: $e");
      return [];
    }
  }
}