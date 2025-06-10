import 'package:dio/dio.dart';

class ApiCustomAgentService {
  late Dio _dio;
  final String baseUrl;
  final String? apiKey;
  final Map<String, dynamic>? customHeaders;
  final String endpoint;
  
  ApiCustomAgentService({
    required this.baseUrl,
    this.apiKey,
    this.customHeaders,
    this.endpoint = '/chat', // Default endpoint
  }) {
    final headers = {
      'Content-Type': 'application/json',
      if (apiKey != null) 'Authorization': 'Bearer $apiKey',
      ...?customHeaders,
    };
    
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        headers: headers,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );
  }

  Future<String> sendChatRequest(String question) async {
    // Support different request formats
    final data = {
      "message": question,
      "query": question, // Some agents use 'query'
      "prompt": question, // Others use 'prompt'
      "input": question, // Or 'input'
      // Include context about the device
      "context": {
        "device": "Even G1 Glasses",
        "interface": "AR Display",
        "constraints": "Short responses preferred (3-4 lines max)",
      }
    };
    
    print("Custom agent request to $baseUrl$endpoint");

    try {
      final response = await _dio.post(endpoint, data: data);

      if (response.statusCode == 200) {
        final responseData = response.data;
        
        // Try different response formats
        String content = "";
        if (responseData is String) {
          content = responseData;
        } else if (responseData is Map) {
          // Try common response fields
          content = responseData['response'] ?? 
                   responseData['message'] ?? 
                   responseData['answer'] ?? 
                   responseData['text'] ?? 
                   responseData['content'] ??
                   responseData['data'] ??
                   "No response field found";
        }
        
        return content.trim();
      } else {
        return "Request failed with status: ${response.statusCode}";
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        return "Connection timeout. Check your agent URL.";
      } else if (e.response != null) {
        return "Agent error: ${e.response?.statusCode}";
      } else {
        return "Failed to connect to agent at $baseUrl";
      }
    }
  }
}

// Preset configurations for popular agent frameworks
class AgentPresets {
  static const Map<String, Map<String, dynamic>> presets = {
    'ollama': {
      'endpoint': '/api/generate',
      'requestFormat': 'ollama',
    },
    'openai-compatible': {
      'endpoint': '/v1/chat/completions',
      'requestFormat': 'openai',
    },
    'langchain': {
      'endpoint': '/chat',
      'requestFormat': 'langchain',
    },
    'custom-rag': {
      'endpoint': '/query',
      'requestFormat': 'rag',
    },
    'autogen': {
      'endpoint': '/chat',
      'requestFormat': 'autogen',
    },
  };
}