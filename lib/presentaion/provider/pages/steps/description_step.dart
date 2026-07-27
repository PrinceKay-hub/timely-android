import 'dart:convert';
import 'package:booking/domain/entities/service_entity.dart';
import 'package:booking/presentaion/provider/cubit/registration/service_registration_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class DescriptionStep extends StatefulWidget {
  final ServiceEntity service;

  const DescriptionStep({super.key, required this.service});

  @override
  State<DescriptionStep> createState() => _DescriptionStepState();
}

class _DescriptionStepState extends State<DescriptionStep> {
  bool _isLoading = false;
  static const int _maxRetries = 3;

  Future<String> _callGeminiWithRetry(String prompt,
      {int attempt = 0}) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent?key=$apiKey',
    );
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ]
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

    if (response.statusCode == 429 &&
        (quotaId?.contains('PerDay') ?? false)) {
      throw Exception('DAILY_QUOTA_EXCEEDED');
    }

    if ((response.statusCode == 503 || response.statusCode == 429) &&
        attempt < _maxRetries) {
      await Future.delayed(Duration(seconds: 1 << attempt));
      return _callGeminiWithRetry(prompt, attempt: attempt + 1);
    }

    throw Exception(
        'Failed to load text: ${response.statusCode} ${response.body}');
  }

  Future<String> _callGroq(String prompt) async {
    final groqApiKey = dotenv.env['GROQ_API_KEY'] ?? '';
    final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $groqApiKey',
      },
      body: jsonEncode({
        'model': 'llama-3.3-70b-versatile',
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content =
          data['choices']?[0]?['message']?['content'] as String?;
      if (content == null) throw Exception('No content returned from Groq');
      return content;
    }

    throw Exception(
        'Groq failed: ${response.statusCode} ${response.body}');
  }

  Future<void> _suggestDescription() async {
    if (widget.service.name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a Service Name first!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prompt =
          'Write a short, professional marketplace description for "${widget.service.name}" under the "${widget.service.category}" category. Keep it under 3 sentences.';

      String aiText;
      try {
        aiText = await _callGeminiWithRetry(prompt);
      } catch (e) {
        debugPrint('Gemini failed, falling back to Groq: $e');
        aiText = await _callGroq(prompt);
      }

      final trimmed = aiText.trim();
      final clamped =
          trimmed.length > 500 ? trimmed.substring(0, 500) : trimmed;
      if (mounted) {
        context.read<ServiceRegistrationCubit>().updateServiceDescription(clamped);
      }
    } catch (e) {
      debugPrint('All providers failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not generate description. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final description = widget.service.description;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.description,
              color: Theme.of(context).colorScheme.primary, size: 60),
          const SizedBox(height: 20),
          const Text('Describe Your Business',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'Tell potential customers about your services and what makes you unique',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Business Description',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(
                      '${description.length}/500',
                      style: TextStyle(
                        color:
                            description.length >= 50 ? Colors.green : Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _suggestDescription,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.auto_awesome, size: 16),
                  label: Text(_isLoading ? 'Writing...' : 'Suggest Description',
                      style: const TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: const StadiumBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                // ValueKey forces a rebuild of the field when AI fills the
                // description so initialValue reflects the new content.
                TextFormField(
                  key: ValueKey(description),
                  initialValue: description,
                  onChanged: context
                      .read<ServiceRegistrationCubit>()
                      .updateServiceDescription,
                  maxLines: 8,
                  maxLength: 500,
                  decoration: InputDecoration(
                    hintText:
                        'Welcome to our salon where we provide exceptional services...',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2),
                    ),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 12),
                if (description.length < 50)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Minimum 50 characters required (${50 - description.length} more)',
                            style: const TextStyle(
                                color: Colors.orange, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}