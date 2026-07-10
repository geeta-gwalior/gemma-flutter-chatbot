import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_mediapipe/flutter_gemma_mediapipe.dart';

class GemmaService {
  bool isModelLoaded = false;
  dynamic _chat;

  Future<void> loadModel() async {
    try {
      await FlutterGemma.initialize(
        inferenceEngines: [MediaPipeEngine()],
        webStorageMode: WebStorageMode.none,
      );

      await FlutterGemma.installModel(
        modelType: ModelType.gemma4,
      ).fromAsset('assets/gemma3-1B-it-int4.task').install();

      final model = await FlutterGemma.getActiveModel(maxTokens: 2048);
      _chat = await model.createChat();

      isModelLoaded = true;
    } catch (e) {
      print("Model load error: $e");
      isModelLoaded = false;
    }
  }

  Future<String> getResponse(String userMessage) async {
    if (!isModelLoaded || _chat == null) {
      return "Model is loading...";
    }
    try {
      await _chat.addQueryChunk(Message.text(text: userMessage, isUser: true));
      final response = await _chat.generateChatResponse();

      if (response == null) return "No response generated.";

      // 1. सबसे पहले चेक करते हैं कि क्या इसमें सीधे .textResponse नाम की प्रॉपर्टी है
      try {
        if ((response as dynamic).textResponse != null) {
          return (response as dynamic).textResponse.toString();
        }
      } catch (_) {}

      // 2. अगर नहीं है, तो TextResponse("...") के बीच की स्ट्रिंग को साफ़ करके निकाल लेते हैं
      String rawString = response.toString();
      if (rawString.startsWith('TextResponse("') && rawString.endsWith('")')) {
        return rawString.substring(14, rawString.length - 2);
      } else if (rawString.startsWith('TextResponse(') && rawString.endsWith(')')) {
        return rawString.substring(13, rawString.length - 1);
      }

      return rawString;
    } catch (e) {
      return "Error: $e";
    }
  }
}