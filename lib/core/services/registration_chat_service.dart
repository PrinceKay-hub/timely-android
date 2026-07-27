import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// A single message in the registration chat.
class ChatMessage {
  final String role; // 'user' or 'assistant'
  final String text;

  ChatMessage({required this.role, required this.text});
}

/// Structured profile extracted once the chat has gathered enough info.
class ExtractedRegistration {
  final String name;
  final String category;
  final String description;
  final List<Map<String, dynamic>> services; // [{name, price, duration}]
  final List<String> workingDays; // e.g. ['Mon', 'Tue']
  final Map<String, int> workingHours; // {startHour, startMinute, endHour, endMinute}
  final List<String> amenities;

  ExtractedRegistration({
    required this.name,
    required this.category,
    required this.description,
    required this.services,
    required this.workingDays,
    required this.workingHours,
    required this.amenities,
  });
}

/// Result of a single conversational turn.
class ChatTurnResult {
  final bool isComplete;
  final String? question;
  final ExtractedRegistration? profile;

  ChatTurnResult.question(this.question)
      : isComplete = false,
        profile = null;

  ChatTurnResult.complete(this.profile)
      : isComplete = true,
        question = null;
}

class RegistrationChatService {
  static const List<String> validDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const List<String> validAmenities = [
    'Free WiFi',
    'Parking',
    'Mobile Money Payment',
    'DSTV',
    'Wheelchair Access',
    'Refreshment',
    'Air Conditioned',
  ];

  static const int maxRetries = 3;
  static const int maxUserTurns = 8; // safety net before forcing extraction

  final List<String> categoryNames;
  late final String _systemPrompt;
  int _userTurnCount = 0;

  RegistrationChatService({required this.categoryNames}) {
    _systemPrompt = _buildSystemPrompt(categoryNames);
  }

  String _buildSystemPrompt(List<String> categories) => '''
You are a friendly onboarding assistant for a service marketplace app. Your
job is to gather enough information through natural conversation to fill out
a complete business profile.

You need to collect:
- name: the business name
- category: MUST be exactly one of these options: ${categories.join(', ')}
- description: enough detail to write a professional 2-3 sentence description
- services: at least one service the business offers, each with a name, a
  price (in Ghana Cedis, numeric), and a duration in minutes
- workingDays: which days they're open, using only these abbreviations: ${validDays.join(', ')}
- workingHours: opening and closing time
- amenities: any that apply from this list (it's fine if none apply): ${validAmenities.join(', ')}

Rules:
- Ask ONE short, friendly question at a time (under 25 words).
- Don't ask about something the user has already told you, even in passing.
- If the user gives multiple pieces of info in one message, acknowledge all of it and move to the next missing piece.
- For category, gently map what the user describes to the closest valid option, confirming naturally rather than just listing options.
- Keep the whole conversation under 8 questions total.
- Once you have name, category, description, at least one service with price+duration, working days, and working hours, STOP asking questions, even if amenities are unknown (default to empty list).
- When done, respond with ONLY this exact format, nothing else before or after:

READY|{"name": "...", "category": "...", "description": "...", "services": [{"name": "...", "price": 0, "duration": 0}], "workingDays": ["Mon"], "workingHours": {"startHour": 9, "startMinute": 0, "endHour": 17, "endMinute": 0}, "amenities": []}

- Never include the READY marker until you actually have the minimum required fields.
- Keep your tone warm and conversational, like a helpful friend setting things up for you, not a form.
''';

  Future<ChatTurnResult> sendMessage(List<ChatMessage> history) async {
    _userTurnCount++;

    String rawResponse;
    try {
      rawResponse = await _callGeminiWithRetry(history);
    } catch (e) {
      // ignore: avoid_print
      print('Gemini chat failed, falling back to Groq: $e');
      rawResponse = await _callGroq(history);
    }

    var result = _parseResponse(rawResponse);

    // Safety net: force a best-effort extraction if the model is still
    // asking questions well past a reasonable point.
    if (!result.isComplete && _userTurnCount >= maxUserTurns) {
      result = await _forceExtraction(history);
    }

    return result;
  }

  Future<ChatTurnResult> _forceExtraction(List<ChatMessage> history) async {
    final finalHistory = [
      ...history,
      ChatMessage(
        role: 'user',
        text:
            'Please give me your best guess for the READY JSON now, using sensible defaults for anything I haven\'t told you.',
      ),
    ];
    String raw;
    try {
      raw = await _callGeminiWithRetry(finalHistory);
    } catch (e) {
      raw = await _callGroq(finalHistory);
    }
    return _parseResponse(raw);
  }

  ChatTurnResult _parseResponse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.startsWith('READY|')) {
      final jsonPart = trimmed.substring('READY|'.length).trim();
      try {
        final data = jsonDecode(jsonPart) as Map<String, dynamic>;
        return ChatTurnResult.complete(_sanitizeProfile(data));
      } catch (e) {
        // ignore: avoid_print
        print('Failed to parse READY payload: $e');
        return ChatTurnResult.question(
          "Sorry, could you repeat that last bit? I didn't quite catch it.",
        );
      }
    }
    return ChatTurnResult.question(trimmed);
  }

  ExtractedRegistration _sanitizeProfile(Map<String, dynamic> raw) {
    // Fuzzy-match category against the real list rather than trusting
    // the model's exact string.
    final rawCategory = (raw['category']?.toString() ?? '').toLowerCase().trim();
    String matchedCategory = categoryNames.firstWhere(
      (c) => c.toLowerCase() == rawCategory,
      orElse: () => categoryNames.firstWhere(
        (c) => c.toLowerCase().contains(rawCategory) || rawCategory.contains(c.toLowerCase()),
        orElse: () => categoryNames.isNotEmpty ? categoryNames.first : '',
      ),
    );

    final rawServices = raw['services'];
    final services = <Map<String, dynamic>>[];
    if (rawServices is List) {
      for (final s in rawServices) {
        if (s is! Map) continue;
        final name = (s['name']?.toString() ?? '').trim();
        final price = double.tryParse(s['price'].toString()) ?? -1;
        final duration = int.tryParse(s['duration'].toString()) ?? -1;
        if (name.isNotEmpty && price > 0 && duration > 0) {
          services.add({'name': name, 'price': price, 'duration': duration});
        }
      }
    }

    final rawDays = raw['workingDays'];
    final workingDays = <String>[];
    if (rawDays is List) {
      for (final d in rawDays) {
        final day = d.toString();
        if (validDays.contains(day)) workingDays.add(day);
      }
    }

    final rawAmenities = raw['amenities'];
    final amenities = <String>[];
    if (rawAmenities is List) {
      for (final a in rawAmenities) {
        final amenity = a.toString();
        if (validAmenities.contains(amenity)) amenities.add(amenity);
      }
    }

    final wh = raw['workingHours'] is Map ? raw['workingHours'] as Map : {};
    final workingHours = {
      'startHour': int.tryParse(wh['startHour'].toString()) ?? 9,
      'startMinute': int.tryParse(wh['startMinute'].toString()) ?? 0,
      'endHour': int.tryParse(wh['endHour'].toString()) ?? 17,
      'endMinute': int.tryParse(wh['endMinute'].toString()) ?? 0,
    };

    return ExtractedRegistration(
      name: (raw['name']?.toString() ?? '').trim(),
      category: matchedCategory,
      description: (raw['description']?.toString() ?? '').trim(),
      services: services,
      workingDays: workingDays,
      workingHours: workingHours,
      amenities: amenities,
    );
  }

  // ---------------- Gemini ----------------

  Future<String> _callGeminiWithRetry(List<ChatMessage> history, {int attempt = 0}) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent?key=$apiKey',
    );

    final contents = history
        .map((m) => {
              'role': m.role == 'assistant' ? 'model' : 'user',
              'parts': [
                {'text': m.text}
              ],
            })
        .toList();

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'system_instruction': {
          'parts': [
            {'text': _systemPrompt}
          ]
        },
        'contents': contents,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final candidates = data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        throw Exception('No candidates returned');
      }
      return candidates[0]['content']['parts'][0]['text'] as String;
    }

    final body = jsonDecode(response.body);
    final quotaId = (body['error']?['details'] as List?)
        ?.firstWhere(
          (d) => (d['@type'] as String?)?.contains('QuotaFailure') ?? false,
          orElse: () => null,
        )?['violations']?[0]?['quotaId'] as String?;

    if (response.statusCode == 429 && (quotaId?.contains('PerDay') ?? false)) {
      throw Exception('DAILY_QUOTA_EXCEEDED');
    }

    if ((response.statusCode == 503 || response.statusCode == 429) && attempt < maxRetries) {
      await Future.delayed(Duration(seconds: 1 << attempt));
      return _callGeminiWithRetry(history, attempt: attempt + 1);
    }

    throw Exception('Gemini failed: ${response.statusCode} ${response.body}');
  }

  // ---------------- Groq fallback ----------------

  Future<String> _callGroq(List<ChatMessage> history) async {
    final groqApiKey = dotenv.env['GROQ_API_KEY'] ?? '';
    final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

    final messages = [
      {'role': 'system', 'content': _systemPrompt},
      ...history.map((m) => {
            'role': m.role == 'assistant' ? 'assistant' : 'user',
            'content': m.text,
          }),
    ];

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $groqApiKey',
      },
      body: jsonEncode({'model': 'llama-3.3-70b-versatile', 'messages': messages}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['choices']?[0]?['message']?['content'] as String?;
      if (content == null) throw Exception('No content returned from Groq');
      return content;
    }

    throw Exception('Groq failed: ${response.statusCode} ${response.body}');
  }
}
